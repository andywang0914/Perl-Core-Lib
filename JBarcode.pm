
package JBarcode;

use strict;
use GD::Barcode::COOP2of5;
use GD::Barcode::Code39;
use GD::Barcode::IATA2of5;
use GD::Barcode::ITF;
use GD::Barcode::Industrial2of5;
use GD::Barcode::Matrix2of5;
use GD::Barcode::NW7;
use GD::Barcode::QRcode;
use Barcode::Code128;

my %local_barcode_types =
(
	'None'						=> 0,
	'QRcode'					=> 1,
	'ITF'							=> 2,	#0-9		
	'IATA2of5'				=> 3, #0-9	
	'Industrial2of5'	=> 4,	#0-9	
	'Matrix2of5'			=> 5,	#0-9	
	'NW7'							=> 6, #0-9, - $ / . + ABCD.
	'Code39'					=> 7,	#0-9, - * + $ % / .  space A-Z.
	'COOP2of5'				=> 8, #0-9
	'Code128'         => 9,
);

sub get_barcode_buffer
{
	my ($class, $code, $type, $no_text) = @_;
	if(!$code)
	{
		return '';
	}
	if($type == $local_barcode_types{'QRcode'})
	{
		return $class->qrcode_buffer($code, $no_text);
	}
	elsif($type == $local_barcode_types{'ITF'})
	{
		return $class->itf_buffer($code, $no_text);	
	}
	elsif($type == $local_barcode_types{'IATA2of5'})
	{
		return $class->iata2of5_buffer($code, $no_text);	
	}
	elsif($type == $local_barcode_types{'Industrial2of5'})
	{
		return $class->industrial2of5_buffer($code, $no_text);	
	}
	elsif($type == $local_barcode_types{'Matrix2of5'})
	{
		return $class->matrix2of5_buffer($code, $no_text);	
	}	
	elsif($type == $local_barcode_types{'NW7'})
	{
		return $class->nw7_buffer($code, $no_text);	
	}
	elsif($type == $local_barcode_types{'Code39'})
	{
		return $class->code39_buffer($code, $no_text);	
	}
	elsif($type == $local_barcode_types{'COOP2of5'})
	{
		return $class->coop2of5_buffer($code, $no_text);	
	}	
	elsif($type == $local_barcode_types{'Code128'})
	{
		return $class->code128_buffer($code, $no_text);
	}
	return '';
}

sub qrcode_buffer
{
	my ($class, $text) = @_;
	return GD::Barcode::QRcode->new("$text",{ Ecc => 'L', Version=>2, ModuleSize => 2})->plot->png;
}

#text has numeric characters([0-9]).
sub coop2of5_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;	
	return GD::Barcode::COOP2of5->new("$text")->plot(NoText=>$no_text)->png;
}

sub code39_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;	
	return GD::Barcode::Code39->new("$text")->plot(NoText=>$no_text)->png;
}

#text has numeric characters([0-9]).
sub iata2of5_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;		
	return GD::Barcode::IATA2of5->new("$text")->plot(NoText=>$no_text)->png;
}

#text has numeric characters([0-9]).
sub itf_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;		
	return GD::Barcode::ITF->new("$text")->plot(NoText=>$no_text)->png;
}

#text has numeric characters([0-9]).
sub industrial2of5_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;		
	return GD::Barcode::Industrial2of5->new("$text")->plot(NoText=>$no_text)->png;
}

#text has numeric characters([0-9]).
sub matrix2of5_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;	
	return GD::Barcode::Matrix2of5->new("$text")->plot(NoText=>$no_text)->png;
}

#text has variable length string with (0-9, - $ / . + ABCD).
sub nw7_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;
	return GD::Barcode::NW7->new("$text")->plot(NoText=>$no_text)->png;
}

sub code128_buffer
{
	my ($class, $text, $no_text) = @_;
	$no_text = $no_text ? 1 : 0;
	my $code = new Barcode::Code128;
	$code->padding(1);
	$code->show_text(!$no_text);
	$code->border(0);
	$code->height(28);
	return $code->png($text);
}


1;
