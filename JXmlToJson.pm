package JXmlToJson;
use strict;
our $VERSION = '0.06';

use Carp;
use XML::LibXML;
use Data::Dump qw(dump);
our $XMLPARSER ||= XML::LibXML->new();

sub new
{
	my $class = shift;
	my $self  = {};
	bless $self, $class;
	$self->_init(@_);
	return $self;
}

sub _init
{
	my $self = shift;
	my %Args = @_;
	my @Modules = qw(JSON::Syck JSON::XS JSON JSON::DWIW);
	if ( $Args{module} )
	{
		my $OK = 0;
		foreach my $Module ( @Modules )
		{
			$OK = 1 if $Module eq $Args{module};
		}
		croak "Unsupported module: $Args{module}" unless $OK;
		@Modules = ( $Args{module} );
	}
	$self->{_loaded_module} = "";

	foreach my $Module ( @Modules )
	{
		eval "use $Module (); 1;";
		unless ($@)
		{
			$self->{_loaded_module} = $Module;
			last;
		}
	}

	croak "Cannot find a suitable JSON module" unless $self->{_loaded_module};

	warn "loaded module: $self->{_loaded_module}";

	# force arrays (this turns off array folding)
	$self->{force_array} =  1;

	# use pretty printing when possible
	$self->{pretty} = 1;

	# debug mode
	$self->{debug} = $Args{debug} ? 1 : 0;

	# names
	$self->{attribute_prefix} = '';
	$self->{content_key}      = defined $Args{content_key}      ? $Args{content_key}      : '$t';

	#
	# sanitize options
	#
	# private_elements
	$self->{private_elements} = {};
	if ($Args{private_elements})
	{
		foreach my $private_element ( @{$Args{private_elements}} )
		{
			# this must account for the ":" to "$" switch
			$private_element =~ s/([^^])\:/$1\$/;
			$self->{private_elements}->{$private_element} = 1;
		}
	}
	# empty_elements
	$self->{empty_elements} = {};
	if ($Args{empty_elements})
	{
		foreach my $empty_element ( @{$Args{empty_elements}} )
		{
			# this must account for the ":" to "$" switch
			$empty_element =~ s/([^^])\:/$1\$/;
			$self->{empty_elements}->{$empty_element} = 1;
		}
	}
	# private_attributes
	$self->{private_attributes} = {};
	if ($Args{private_attributes})
	{
		foreach my $private_attribute ( @{$Args{private_attributes}} )
		{
			# this must account for the attribute_prefix
			$self->{private_attributes}->{ $self->{attribute_prefix} . $private_attribute } = 1;
		}
	}

	return;
}

sub convert
{
	my ( $self, $XML ) = @_;

	my $Obj = $self->xml2obj($XML);

	if ( %{ $self->{private_elements} } || %{ $self->{empty_elements} } || %{ $self->{private_attributes} } )
	{
		$self->sanitize($Obj);
	}

	my $JSON = $self->obj2json($Obj);

	return $JSON;
}


sub xml2json
{
	my ( $self, $XML ) = @_;

	my $JSON = $self->convert($XML);

	return $JSON;
}

sub obj2json
{
	my ( $self, $Obj ) = @_;

	my $JSON = "";

	carp "Converting obj to json using $self->{_loaded_module}" if $self->{debug};

	if ( $self->{_loaded_module} eq 'JSON::Syck' )
	{
		# this module does not have a "pretty" option
		$JSON = JSON::Syck::Dump($Obj);
	}

	if ( $self->{_loaded_module} eq 'JSON::XS' )
	{
		$JSON = JSON::XS->new->utf8->pretty( $self->{pretty} )->encode($Obj);
	}

	if ( $self->{_loaded_module} eq 'JSON' )
	{
		$JSON::UnMapping = 1;

		if ( $self->{pretty} )
		{
			$JSON = JSON::to_json( $Obj, { pretty => 1, indent => 2 } );
		}
		else
		{
			$JSON = JSON::to_json($Obj);
		}
	}

	if ( $self->{_loaded_module} eq 'JSON::DWIW' )
	{
		$JSON = JSON::DWIW->to_json( $Obj, { pretty => $self->{pretty} } );
	}

	return $JSON;
}

sub dom2obj
{
	my ( $self, $Doc ) = @_;
	# this is the response element
	my $Root = $Doc->documentElement;
	# set the root element name
	my $NodeName = $Root->nodeName;
	# replace a ":" in the name with a "$"
	$NodeName =~ s/([^^])\:/$1\$/;
	# get the version and encoding of the xml doc
	my $Version  = $Doc->version  || '1.0';
	my $Encoding = $Doc->encoding || 'UTF-8';
	# create the base objects
	my $Obj;
	my $isArrayNode = $self->isArrayNode($Root);
	if($isArrayNode)
	{
		$Obj = [];
	}
	else
	{
		$Obj = {};
	}
	my $RootObj = {
		$NodeName => $Obj,
	};
	# grab any text content
	my $Text = $Root->findvalue('text()');
	$Text = undef unless $Text =~ /\S/;
	$Obj->{ $self->{content_key} } = $Text if defined($Text);
	if(defined($Text))
	{
		$RootObj->{$NodeName} = $Text;
		return $RootObj;
	}
	# process attributes
	my @Attributes = $Root->findnodes('@*');
	if (@Attributes)
	{
		foreach my $Attr (@Attributes)
		{
			my $AttrName  = $Attr->nodeName;
			my $AttrValue = $Attr->nodeValue;
			$Obj->{ $self->{attribute_prefix} . $AttrName } = $AttrValue;
		}
	}
	my @Namespaces = $Root->getNamespaces();
	if (@Namespaces)
	{
		foreach my $Ns (@Namespaces)
		{
			my $Prefix = $Ns->declaredPrefix;
			my $URI = $Ns->declaredURI;
			$Prefix = ":$Prefix" if $Prefix;
			$Obj->{ $self->{attribute_prefix} . 'xmlns' . $Prefix } = $URI;
			warn "xmlns$Prefix=\"$URI\"" if $self->{debug};
		}
	}
	$self->_process_children( $Root, $Obj );
	return $RootObj;
}

sub xml2obj
{
	my ( $self, $XML ) = @_;

	my $Doc = $XMLPARSER->parse_string($XML);

	my $Obj = $self->dom2obj($Doc);

	return $Obj;
}

sub isArrayNode
{
	my ( $self, $Node ) = @_;
	my $Text = $Node->findvalue('text()');
	$Text = undef unless $Text =~ /\S/;
	if(defined($Text))
	{
		return 0;
	}
	my $NodeName = $Node->nodeName;
	if($NodeName =~ /Response$/sg)
	{
		return 0;
	}
	my $all_same_tag = 1;
	my @Children = $Node->findnodes('*');
	my $tnodeName;
	foreach my $Child (@Children)
	{
		if(!$tnodeName)
		{
			$tnodeName = $Child->nodeName;
		}
		if($tnodeName ne $Child->nodeName)
		{
			$all_same_tag = 0;
			last;
		}
	}
	return $all_same_tag;
}

sub _process_children
{
	my ( $self, $CurrentElement, $CurrentObj) = @_;
	my @Children = $CurrentElement->findnodes('*');
	foreach my $Child (@Children)
	{
		# this will contain the data for the current element (including its children)
		my $ElementHash = {};
		my $isArray = ref $CurrentObj eq "ARRAY";
		# set the name of the element
		my $NodeName = $Child->nodeName;
		# replace a ":" in the name with a "$"
		$NodeName =~ s/([^^])\:/$1\$/;

		warn "Found element: $NodeName" if $self->{debug};

		# force array: all children are accessed through an arrayref, even if there is only one child
		# I don't think I like this, but it's more predictable than array folding
		my $isArrayNode = $self->isArrayNode($Child);
		if ($isArrayNode && !$isArray)
		{
			warn "Forcing \"$NodeName\" element into an array" if $self->{debug};
			$CurrentObj->{$NodeName} = [];
		}
		else
		{
			# grab any text content
			my $Text = $Child->findvalue('text()');
			$Text = undef unless $Text =~ /\S/;
			if(defined($Text))
			{
				if ($isArray)
				{
					push @{ $CurrentObj}, $Text;
				}
				else
				{
					$CurrentObj->{$NodeName} = $Text if defined($Text);
				}
				next;
			}
			# check to see if a sibling element of this node name has already been added to the current object block
			if ($isArray)
			{
				# add the current element to the array
				warn "Adding the \"$NodeName\" child element to the array" if $self->{debug};
				push @{ $CurrentObj}, $ElementHash;
			}
			# this is the first element found for this node name, so just add the hash
			# this will simplify data access for elements that only have a single child of the same name
			else
			{
				warn "Found the first \"$NodeName\" child element."
				. " This element may be accessed directly through its hashref"
				if $self->{debug};
				$CurrentObj->{$NodeName} = $ElementHash;
			}
		}
		# add the attributes
		my @Attributes = $Child->findnodes('@*');
		if (@Attributes)
		{
			foreach my $Attr (@Attributes)
			{
				my $AttrName  = $self->{attribute_prefix} . $Attr->nodeName;
				my $AttrValue = $Attr->nodeValue;

				# prefix the attribute name so that the name cannot conflict with child element names
				warn "Adding attribute to the \"$NodeName\" element: $AttrName" if $self->{debug};
				$ElementHash->{$AttrName} = $AttrValue;
			}
		}
		my @Namespaces = $Child->getNamespaces();
		if (@Namespaces)
		{
			foreach my $Ns (@Namespaces)
			{
				my $Prefix = $Ns->declaredPrefix;
				my $URI = $Ns->declaredURI;
				$Prefix = ":$Prefix" if $Prefix;
				$ElementHash->{ $self->{attribute_prefix} . 'xmlns' . $Prefix } = $URI;
				warn "xmlns$Prefix=\"$URI\"" if $self->{debug};
			}
		}
		# look for more children
		$self->_process_children( $Child, $isArrayNode ? $CurrentObj->{$NodeName} : $ElementHash);
	}

	return;
}

sub sanitize
{
	my ( $self, $Obj ) = @_;

	my $ObjType = ref($Obj) || 'scalar';
	carp "That's not a hashref! ($ObjType)" unless $ObjType eq 'HASH';

	# process each hash key
	KEYS: foreach my $Key ( keys %$Obj )
	{
		my $KeyType = ref( $Obj->{$Key} );

		# this is an element
		if ( $KeyType eq 'HASH' || $KeyType eq 'ARRAY' )
		{
			# check to see if this element is private
			if ( $self->{private_elements}->{$Key} )
			{
				# this is a private element, so delete it
				warn "Deleting private element: $Key" if $self->{debug};
				delete $Obj->{$Key};

				# the element is gone, move on to the next hash key
				next KEYS;
			}

			# the element is a hash
			if ( $KeyType eq 'HASH' )
			{
				# check to see if this element should be blanked out
				if ( $self->{empty_elements}->{$Key} )
				{
					my @Attributes = keys %{ $Obj->{$Key} };

					foreach my $Attribute (@Attributes)
					{
						unless ( ref( $Obj->{$Key}->{$Attribute} ) )
						{
							warn "Deleting attribute from \"$Key\" element: $Attribute" if $self->{debug};
							delete $Obj->{$Key}->{$Attribute};
						}
					}
				}

				# go deeper
				$self->sanitize( $Obj->{$Key} );
			}

			# this is an array of child elements
			if ( $KeyType eq 'ARRAY' )
			{
				# process each child element
				foreach my $Element ( @{ $Obj->{$Key} } )
				{
					$self->sanitize($Element);
				}
			}
		}
		# this is an attribute
		elsif ( !$KeyType )
		{
			# check to see if the attribute is private
			if ( $self->{private_attributes}->{$Key} )
			{
				# this is a private attribute, so delete it
				warn "Deleting private attribute: $Key" if $self->{debug};
				delete $Obj->{$Key};
			}
		}
		else
		{
			croak "Invalid data type for key: $Key (data type: $KeyType)";
		}
	}

	return;
}

sub json2xml
{
	my ( $self, $JSON ) = @_;

	my $Obj = $self->json2obj($JSON);

	my $XML = $self->obj2xml($Obj);

	return $XML;
}

sub json2obj
{
	my ( $self, $JSON ) = @_;

	my $Obj;

	carp "Converting json to obj using $self->{_loaded_module}" if $self->{debug};

	if ( $self->{_loaded_module} eq 'JSON::Syck' )
	{
		$Obj = JSON::Syck::Load($JSON);
	}

	if ( $self->{_loaded_module} eq 'JSON::XS' )
	{
		$Obj = JSON::XS->new->utf8->decode($JSON);
	}

	if ( $self->{_loaded_module} eq 'JSON' )
	{
		$Obj = JSON::from_json($JSON);
	}

	if ( $self->{_loaded_module} eq 'JSON::DWIW' )
	{
		$Obj = JSON::DWIW->from_json($JSON);
	}

	return $Obj;
}

sub obj2dom
{
	my ( $self, $Obj ) = @_;

	croak "Object must be a hashref" unless ref($Obj) eq 'HASH';

	my $Version  = $Obj->{ $self->{attribute_prefix} . 'version' }  || $Obj->{'version'}  || '1.0';
	my $Encoding = $Obj->{ $self->{attribute_prefix} . 'encoding' } || $Obj->{'encoding'} || 'UTF-8';

	my $Dom = $XMLPARSER->createDocument( $Version, $Encoding );

	my $GotRoot = 0;

	#delete @$Obj{ grep { /^$self->{attribute_prefix}/ } keys %$Obj };

	foreach my $Key ( keys %$Obj )
	{
		$Obj->{$Key} = "" unless defined($Obj->{$Key});

		my $RefType = ref( $Obj->{$Key} );
		warn "Value ref type for $Key is: $RefType (value seems to be $Obj->{$Key})" if $self->{debug};

		my $Name = $Key;

		# replace a "$" in the name with a ":"
		$Name =~ s/([^^])\$/$1\:/;

		if ( $RefType eq 'HASH' )
		{
			warn "Creating root element: $Name" if $self->{debug};

			croak "You may only have one root element: $Key" if $GotRoot;
			$GotRoot = 1;

			my $Root = $Dom->createElement($Name);
			$Dom->setDocumentElement($Root);

			$self->_process_element_hash( $Dom, $Root, $Obj->{$Key} );
		}
		elsif ( $RefType eq 'ARRAY' )
		{
			croak "You cant have an array of root nodes: $Key";
		}
		elsif ( !$RefType )
		{
			if ( $Obj->{$Key} ne '' )
			{
				unless ($GotRoot)
				{
					my $Root;
					eval { $Root = $Dom->createElement($Name) };
					if ( $@ ) {
						die "Problem creating root element $Name: $@";
					}
					$Dom->setDocumentElement($Root);
					$Root->appendText( $Obj->{$Key} );
					$GotRoot = 1;
				}
			}
			else
			{
				croak "Invalid data for key: $Key";
			}
		}
		else
		{
			warn "unknown reference: $RefType";
		}
	}

	return $Dom;
}

sub obj2xml
{
	my ( $self, $Obj ) = @_;

	my $Dom = $self->obj2dom($Obj);

	my $XML = $Dom->toString( $self->{pretty} ? 2 : 0 );

	return $XML;
}

sub _process_element_hash
{
	my ( $self, $Dom, $Element, $Obj ) = @_;

	foreach my $Key ( keys %$Obj )
	{
		my $RefType = ref( $Obj->{$Key} );

		my $Name = $Key;

		# replace a "$" in the name with a ":"
		$Name =~ s/([^^])\$/$1\:/;

		# true/false hacks
		if ($RefType eq 'JSON::XS::Boolean')
		{
			$RefType = "";
			$Obj->{$Key} = 1 if ("$Obj->{$Key}" eq 'true');
			$Obj->{$Key} = "" if ("$Obj->{$Key}" eq 'false');
		}
		if ($RefType eq 'JSON::true')
		{
			$RefType = "";
			$Obj->{$Key} = 1;
		}
		if ($RefType eq 'JSON::false')
		{
			$RefType = "";
			$Obj->{$Key} = "";
		}

		if ( $RefType eq 'ARRAY' )
		{
			foreach my $ChildObj ( @{ $Obj->{$Key} } )
			{
				warn "Creating element: $Name" if $self->{debug};

				my $Child = $Dom->createElement($Name);
				$Element->addChild($Child);

				$self->_process_element_hash( $Dom, $Child, $ChildObj );
			}
		}
		elsif ( $RefType eq 'HASH' )
		{
			warn "Creating element: $Name" if $self->{debug};

			my $Child = $Dom->createElement($Name);
			$Element->addChild($Child);

			$self->_process_element_hash( $Dom, $Child, $Obj->{$Key} );
		}
		elsif ( !$RefType )
		{
			if ( $Key eq $self->{content_key} )
			{
				warn "Appending text to: $Name" if $self->{debug};

				my $Value = defined($Obj->{$Key}) ? $Obj->{$Key} : q{};

				$Element->appendText( $Value );
			}
			else
			{

				# remove the attribute prefix
				my $AttributePrefix = $self->{attribute_prefix};
				if ( $Name =~ /^\Q$AttributePrefix\E(.+)/ )
				{
					$Name = $1;
				}

				my $Value = defined($Obj->{$Key}) ? $Obj->{$Key} : q{};

				warn "Creating attribute: $Name" if $self->{debug};
				$Element->setAttribute( $Name, $Value );
			}
		}
		else
		{
			croak "Invalid value for element $Key (reference type: $RefType)";
		}
	}

	return;
}


1;

