#############################################################################
## Name:        Parser.pm
## Purpose:     Pod::HtmlEasy::Parser
## Author:      Graciliano M. P.
## Modified by:
## Created:     11/01/2004
## RCS-ID:      
## Copyright:   (c) 2004 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy::Parser ;

use strict qw(vars);

use Pod::Parser ;

use vars qw($VERSION @ISA) ;
$VERSION = '0.01' ;
@ISA = qw(Pod::Parser) ;

########
# VARS #
########

  #use Regexp::Common ;
  #my $URI_RE = $RE{URI} ;
  
  my $URI_RE = q`(?:(?:(?:nntp)://(?:(?:(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?)/(?:(?:[a-zA-Z][-A-Za-z0-9.+_]*))(?:/(?:[0-9]+))?))|(?:(?:pop)://(?:(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),&=~]+|(?:%[a-fA-F0-9][a-fA-F0-9]))+))(?:;AUTH=(?:[*]|(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),&=~]+|(?:%[a-fA-F0-9][a-fA-F0-9]))+)|(?:[+](?:APOP|(?:(?:[-a-zA-Z0-9$_.+!*'(),&=~]+|(?:%[a-fA-F0-9][a-fA-F0-9]))+))))))?@)?(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?)|(?:(?:wais)://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?/(?:(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))(?:[?](?:(?:(?:[-a-zA-Z0-9$_.+!*'(),;:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))|/(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))/(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)))?))|(?:(?:ftp)://(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'();:&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))(?:)@)?(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))(?:;type=(?:[AIai]))?))?)|(?:(?:tel):(?:(?:(?:[+](?:[0-9\-.()]+)(?:;isub=[0-9\-.()]+)?(?:;postd=[0-9\-.()*#ABCDwp]+)?(?:(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))|(?:;(?:tsp)=(?: |(?:(?:(?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?)(?:[.](?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?))*))))|(?:;(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:=(?:(?:(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:[?](?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*))?)|(?:%22(?:(?:%5C(?:[a-zA-Z0-9\-_.!~*'()]|(?:%[a-fA-F0-9][a-fA-F0-9])))|[a-zA-Z0-9\-_.!~*'()]+|(?:%(?:[01][a-fA-F0-9])|2[013-9A-Fa-f]|[3-9A-Fa-f][a-fA-F0-9]))*%22)))?))*)|(?:[0-9\-.()*#ABCDwp]+(?:;isub=[0-9\-.()]+)?(?:;postd=[0-9\-.()*#ABCDwp]+)?(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))(?:(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))|(?:;(?:tsp)=(?: |(?:(?:(?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?)(?:[.](?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?))*))))|(?:;(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:=(?:(?:(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:[?](?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*))?)|(?:%22(?:(?:%5C(?:[a-zA-Z0-9\-_.!~*'()]|(?:%[a-fA-F0-9][a-fA-F0-9])))|[a-zA-Z0-9\-_.!~*'()]+|(?:%(?:[01][a-fA-F0-9])|2[013-9A-Fa-f]|[3-9A-Fa-f][a-fA-F0-9]))*%22)))?))*))))|(?:(?:prospero)://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?/(?:(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),?:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[-a-zA-Z0-9$_.+!*'(),?:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))(?:(?:;(?:(?:[-a-zA-Z0-9$_.+!*'(),?:@&]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)=(?:(?:[-a-zA-Z0-9$_.+!*'(),?:@&]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))|(?:(?:tv):(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?))?)|(?:(?:telnet)://(?:(?:(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),;?&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))(?::(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),;?&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)))?)@)?(?:(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?)(?:/)?)|(?:(?:news):(?:(?:[*]|(?:(?:[-a-zA-Z0-9$_.+!*'(),;/?:&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))+@(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))|(?:[a-zA-Z][-A-Za-z0-9.+_]*))))|(?:(?:gopher)://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]+)))?/(?:(?:(?:[0-9+IgT]))(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))))|(?:(?:file)://(?:(?:(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z]))|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+))|localhost)?)(?:/(?:(?:(?:(?:[-a-zA-Z0-9$_.+!*'(),:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:/(?:(?:[-a-zA-Z0-9$_.+!*'(),:@&=]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*)))))|(?:(?:fax):(?:(?:(?:[+](?:[0-9\-.()]+)(?:;isub=[0-9\-.()]+)?(?:;tsub=[0-9\-.()]+)?(?:;postd=[0-9\-.()*#ABCDwp]+)?(?:(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))|(?:;(?:tsp)=(?: |(?:(?:(?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?)(?:[.](?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?))*))))|(?:;(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:=(?:(?:(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:[?](?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*))?)|(?:%22(?:(?:%5C(?:[a-zA-Z0-9\-_.!~*'()]|(?:%[a-fA-F0-9][a-fA-F0-9])))|[a-zA-Z0-9\-_.!~*'()]+|(?:%(?:[01][a-fA-F0-9])|2[013-9A-Fa-f]|[3-9A-Fa-f][a-fA-F0-9]))*%22)))?))*)|(?:[0-9\-.()*#ABCDwp]+(?:;isub=[0-9\-.()]+)?(?:;tsub=[0-9\-.()]+)?(?:;postd=[0-9\-.()*#ABCDwp]+)?(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))(?:(?:;(?:phone-context)=(?:(?:(?:[+][0-9\-.()]+)|(?:[0-9\-.()*#ABCDwp]+))|(?:(?:[!'E-OQ-VX-Z_e-oq-vx-z~]|(?:%(?:2[124-7CFcf]|3[AC-Fac-f]|4[05-9A-Fa-f]|5[1-689A-Fa-f]|6[05-9A-Fa-f]|7[1-689A-Ea-e])))(?:[!'()*\-.0-9A-Z_a-z~]+|(?:%(?:2[1-9A-Fa-f]|3[AC-Fac-f]|[4-6][0-9A-Fa-f]|7[0-9A-Ea-e])))*)))|(?:;(?:tsp)=(?: |(?:(?:(?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?)(?:[.](?:[A-Za-z](?:(?:(?:[-A-Za-z0-9]+)){0,61}[A-Za-z0-9])?))*))))|(?:;(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:=(?:(?:(?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*)(?:[?](?:(?:[!'*\-.0-9A-Z_a-z~]+|%(?:2[13-7ABDEabde]|3[0-9]|4[1-9A-Fa-f]|5[AEFaef]|6[0-9A-Fa-f]|7[0-9ACEace]))*))?)|(?:%22(?:(?:%5C(?:[a-zA-Z0-9\-_.!~*'()]|(?:%[a-fA-F0-9][a-fA-F0-9])))|[a-zA-Z0-9\-_.!~*'()]+|(?:%(?:[01][a-fA-F0-9])|2[013-9A-Fa-f]|[3-9A-Fa-f][a-fA-F0-9]))*%22)))?))*))))|(?:(?:http)://(?:(?:(?:(?:(?:(?:[a-zA-Z0-9][-a-zA-Z0-9]*)?[a-zA-Z0-9])[.])*(?:[a-zA-Z][-a-zA-Z0-9]*[a-zA-Z0-9]|[a-zA-Z])[.]?)|(?:[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+)))(?::(?:(?:[0-9]*)))?(?:/(?:(?:(?:(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*)(?:/(?:(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)(?:;(?:(?:[a-zA-Z0-9\-_.!~*'():@&=+$,]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*))*))*))(?:[?](?:(?:(?:[;/?:@&=+$,a-zA-Z0-9\-_.!~*'()]+|(?:%[a-fA-F0-9][a-fA-F0-9]))*)))?))?))` ;  
    
  my $MAIL_RE = qr/([\w-]+\@[\w-]+(?:\.[\w-\.]+\.[\w-]+|\.[\w-]+|))/s ;
  
  use vars qw(%ENTITIES) ;
  
  %ENTITIES = (
  ntilde    => 'ñ' ,
  Acirc     => 'Â' ,
  AElig     => 'Æ' ,
  Euml      => 'Ë' ,
  Yacute    => 'Ý' ,
  euml      => 'ë' ,
  deg       => '°' ,
  ucirc     => 'û' ,
  igrave    => 'ì' ,
  Oacute    => 'Ó' ,
  Eacute    => 'É' ,
  acute     => '´' ,
  THORN     => 'Þ' ,
  Ugrave    => 'Ù' ,
  Atilde    => 'Ã' ,
  ccedil    => 'ç' ,
  Iuml      => 'Ï' ,
  szlig     => 'ß' ,
  Ecirc     => 'Ê' ,
  iuml      => 'ï' ,
  Agrave    => 'À' ,
  aring     => 'å' ,
  macr      => '¯' ,
  laquo     => '«' ,
  cedil     => '¸' ,
  copy      => '©' ,
  acirc     => 'â' ,
  Iacute    => 'Í' ,
  aelig     => 'æ' ,
  ETH       => 'Ð' ,
  Otilde    => 'Õ' ,
  Icirc     => 'Î' ,
  iexcl     => '¡' ,
  Ograve    => 'Ò' ,
  Ouml      => 'Ö' ,
  yen       => '¥' ,
  oslash    => 'ø' ,
  ouml      => 'ö' ,
  frac12    => '½' ,
  Egrave    => 'È' ,
  uacute    => 'ú' ,
  uml       => '¨' ,
  micro     => 'µ' ,
  frac14    => '¼' ,
  aacute    => 'á' ,
  ecirc     => 'ê' ,
  raquo     => '»' ,
  iquest    => '¿' ,
  middot    => '·' ,
  times     => '×' ,
  Ntilde    => 'Ñ' ,
  sect      => '§' ,
  plusmn    => '±' ,
  curren    => '¤' ,
  not       => '¬' ,
  Uuml      => 'Ü' ,
  Igrave    => 'Ì' ,
  uuml      => 'ü' ,
  yacute    => 'ý' ,
  Ocirc     => 'Ô' ,
  icirc     => 'î' ,
  oacute    => 'ó' ,
  shy       => '­' ,
  ordf      => 'ª' ,
  eacute    => 'é' ,
  ugrave    => 'ù' ,
  Ccedil    => 'Ç' ,
  atilde    => 'ã' ,
  ordm      => 'º' ,
  para      => '¶' ,
  yuml      => 'ÿ' ,
  agrave    => 'à' ,
  divide    => '÷' ,
  nbsp      => ' ' ,
  iacute    => 'í' ,
  Ucirc     => 'Û' ,
  otilde    => 'õ' ,
  sup1      => '¹' ,
  ocirc     => 'ô' ,
  eth       => 'ð' ,
  sup2      => '²' ,
  sup3      => '³' ,
  brvbar    => '¦' ,
  ograve    => 'ò' ,
  Oslash    => 'Ø' ,
  Uacute    => 'Ú' ,
  reg       => '®' ,
  egrave    => 'è' ,
  thorn     => 'þ' ,
  Auml      => 'Ä' ,
  Aacute    => 'Á' ,
  frac34    => '¾' ,
  auml      => 'ä' ,
  cent      => '¢' ,
  Aring     => 'Å' ,
  pound     => '£' ,
   ( $] > 5.007 ? (
   OElig    => chr(338),
   oelig    => chr(339),
   Scaron   => chr(352),
   scaron   => chr(353),
   Yuml     => chr(376),
   fnof     => chr(402),
   circ     => chr(710),
   tilde    => chr(732),
   Alpha    => chr(913),
   Beta     => chr(914),
   Gamma    => chr(915),
   Delta    => chr(916),
   Epsilon  => chr(917),
   Zeta     => chr(918),
   Eta      => chr(919),
   Theta    => chr(920),
   Iota     => chr(921),
   Kappa    => chr(922),
   Lambda   => chr(923),
   Mu       => chr(924),
   Nu       => chr(925),
   Xi       => chr(926),
   Omicron  => chr(927),
   Pi       => chr(928),
   Rho      => chr(929),
   Sigma    => chr(931),
   Tau      => chr(932),
   Upsilon  => chr(933),
   Phi      => chr(934),
   Chi      => chr(935),
   Psi      => chr(936),
   Omega    => chr(937),
   alpha    => chr(945),
   beta     => chr(946),
   gamma    => chr(947),
   delta    => chr(948),
   epsilon  => chr(949),
   zeta     => chr(950),
   eta      => chr(951),
   theta    => chr(952),
   iota     => chr(953),
   kappa    => chr(954),
   lambda   => chr(955),
   mu       => chr(956),
   nu       => chr(957),
   xi       => chr(958),
   omicron  => chr(959),
   pi       => chr(960),
   rho      => chr(961),
   sigmaf   => chr(962),
   sigma    => chr(963),
   tau      => chr(964),
   upsilon  => chr(965),
   phi      => chr(966),
   chi      => chr(967),
   psi      => chr(968),
   omega    => chr(969),
   thetasym => chr(977),
   upsih    => chr(978),
   piv      => chr(982),
   ensp     => chr(8194),
   emsp     => chr(8195),
   thinsp   => chr(8201),
   zwnj     => chr(8204),
   zwj      => chr(8205),
   lrm      => chr(8206),
   rlm      => chr(8207),
   ndash    => chr(8211),
   mdash    => chr(8212),
   lsquo    => chr(8216),
   rsquo    => chr(8217),
   sbquo    => chr(8218),
   ldquo    => chr(8220),
   rdquo    => chr(8221),
   bdquo    => chr(8222),
   dagger   => chr(8224),
   Dagger   => chr(8225),
   bull     => chr(8226),
   hellip   => chr(8230),
   permil   => chr(8240),
   prime    => chr(8242),
   Prime    => chr(8243),
   lsaquo   => chr(8249),
   rsaquo   => chr(8250),
   oline    => chr(8254),
   frasl    => chr(8260),
   euro     => chr(8364),
   image    => chr(8465),
   weierp   => chr(8472),
   real     => chr(8476),
   trade    => chr(8482),
   alefsym  => chr(8501),
   larr     => chr(8592),
   uarr     => chr(8593),
   rarr     => chr(8594),
   darr     => chr(8595),
   harr     => chr(8596),
   crarr    => chr(8629),
   lArr     => chr(8656),
   uArr     => chr(8657),
   rArr     => chr(8658),
   dArr     => chr(8659),
   hArr     => chr(8660),
   forall   => chr(8704),
   part     => chr(8706),
   exist    => chr(8707),
   empty    => chr(8709),
   nabla    => chr(8711),
   isin     => chr(8712),
   notin    => chr(8713),
   ni       => chr(8715),
   prod     => chr(8719),
   sum      => chr(8721),
   minus    => chr(8722),
   lowast   => chr(8727),
   radic    => chr(8730),
   prop     => chr(8733),
   infin    => chr(8734),
   ang      => chr(8736),
  'and'     => chr(8743),
  'or'      => chr(8744),
   cap      => chr(8745),
   cup      => chr(8746),
  'int'     => chr(8747),
   there4   => chr(8756),
   sim      => chr(8764),
   cong     => chr(8773),
   asymp    => chr(8776),
  'ne'      => chr(8800),
   equiv    => chr(8801),
  'le'      => chr(8804),
  'ge'      => chr(8805),
  'sub'     => chr(8834),
   sup      => chr(8835),
   nsub     => chr(8836),
   sube     => chr(8838),
   supe     => chr(8839),
   oplus    => chr(8853),
   otimes   => chr(8855),
   perp     => chr(8869),
   sdot     => chr(8901),
   lceil    => chr(8968),
   rceil    => chr(8969),
   lfloor   => chr(8970),
   rfloor   => chr(8971),
   lang     => chr(9001),
   rang     => chr(9002),
   loz      => chr(9674),
   spades   => chr(9824),
   clubs    => chr(9827),
   hearts   => chr(9829),
   diams    => chr(9830),
   ) : ())
  );

  my @CHAR_2_ENTITY_ORDER = (qw(& < >) , sort values %ENTITIES) ;

  {
    my %ENTITIES_BASIC = (
    amp  => '&' ,
    'gt' => '>' ,
    'lt' => '<' ,
    #quot => '"' ,
    #apos => "'" ,
    ) ;
    foreach my $Key ( keys %ENTITIES_BASIC ) { $ENTITIES{$Key} = $ENTITIES_BASIC{$Key} ;}
  }
  
  my %CHAR_2_ENTITY ;
  foreach my $Key ( keys %ENTITIES ) { $CHAR_2_ENTITY{ $ENTITIES{$Key} } = "&$Key;" ;}

#############
# BEGIN_POD #
#############

sub begin_pod {
  my ( $parser ) = @_ ;

  return if $parser->{POD_HTMLEASY_INCLUDE} ;

  $parser->{POD_HTMLEASY}{MARK_FILTER}{MARK} = "\0#\0MARK_FILTER\0" ;
  
  delete $parser->{POD_HTMLEASY}->{INDEX} ;
  $parser->{POD_HTMLEASY}->{INDEX} = { tree => [] } ;

  return 1 ;
}

###########
# END_POD #
###########

sub end_pod {
  my ( $parser ) = @_ ;

  return if $parser->{POD_HTMLEASY_INCLUDE} ;
  
  _remove_mark_filter($parser , $parser->{POD_HTMLEASY}->{OUTPUT} ) ;

  delete $parser->{POD_HTMLEASY}{MARK_FILTER} ;
  
  my $tree = $parser->{POD_HTMLEASY}->{INDEX}{tree} ;
  
  delete $parser->{POD_HTMLEASY}->{INDEX} ;
  
  $parser->{POD_HTMLEASY}->{INDEX} = $tree ;

  return 1 ;
}

###########
# COMMAND #
###########

sub command { 
  my ($parser, $command, $paragraph, $line_num , $pod) = @_;
  
  _verbatim($parser) if $parser->{POD_HTMLEASY}->{VERBATIN_BUFFER} ne '' ;
    
  my $output = $parser->output_handle() ;
    
  my $expansion = $parser->interpolate($paragraph, $line_num) ;
  
  $expansion =~ s/\s+$//s ;
  
  _encode_entities($parser , \$expansion) ;
  _add_uri_href($parser , \$expansion) ;

  _remove_mark_filter($parser , \$expansion) ;  
  
  my $a_name = $expansion ;
  $a_name =~ s/<.*?>//gs ;
  $a_name =~ s/\W/-/gs ;
    
  my $html ;
  if ( $command eq 'head1' ) {
    _add_tree_point($parser , $expansion , 1) ;
    $html = &{$parser->{POD_HTMLEASY}->{ON_HEAD1}}($parser->{POD_HTMLEASY} , $expansion , $a_name ) ;
  }
  elsif ( $command eq 'head2' ) {
    _add_tree_point($parser , $expansion , 2) ;
    $html = &{$parser->{POD_HTMLEASY}->{ON_HEAD2}}($parser->{POD_HTMLEASY} , $expansion , $a_name ) ;
  }
  elsif ( $command eq 'head3' ) {
    _add_tree_point($parser , $expansion , 3) ;
    $html = &{$parser->{POD_HTMLEASY}->{ON_HEAD3}}($parser->{POD_HTMLEASY} , $expansion , $a_name ) ;
  }
  elsif ( $command eq 'over' ) {
    if ( $parser->{INDEX_ITEM} ) { $parser->{INDEX_ITEM_LEVEL}++ ;}
    $html = &{$parser->{POD_HTMLEASY}->{ON_OVER}}($parser->{POD_HTMLEASY} , $expansion ) ;
  }
  elsif ( $command eq 'item' ) {
    if ( $parser->{INDEX_ITEM} ) {
      _add_tree_point($parser , $expansion , (3 + ($parser->{INDEX_ITEM_LEVEL} || 1)) ) ;
    }
    $html = &{$parser->{POD_HTMLEASY}->{ON_ITEM}}($parser->{POD_HTMLEASY} , $expansion , $a_name ) ;
  }
  elsif ( $command eq 'back' ) {
    if ( $parser->{INDEX_ITEM} ) { $parser->{INDEX_ITEM_LEVEL}-- ;}
    $html = &{$parser->{POD_HTMLEASY}->{ON_BACK}}($parser->{POD_HTMLEASY} , $expansion ) ;
  }
  elsif ( $command eq 'include' ) {
    my $file = &{$parser->{POD_HTMLEASY}->{ON_INCLUDE}}($parser->{POD_HTMLEASY} , $expansion ) ;
    $parser->{POD_HTMLEASY}->parse_include($file) ;
  }
  elsif ( defined $parser->{POD_HTMLEASY}->{"ON_\U$command\E"} ) {
    $html = &{$parser->{POD_HTMLEASY}->{"ON_\U$command\E"}}($parser->{POD_HTMLEASY} , $expansion ) ;
  }
  elsif ( $command =~ /^(?:pod|cut)$/i ) { ; }
  else {
    $html = "<pre>=$command $expansion</pre>" ;
  }
  
  print $output $html if $html ne '' ;
}

###################
# _ADD_TREE_POINT #
###################

sub _add_tree_point {
  my ( $parser , $name , $level ) = @_ ;
  $level ||= 1 ;
  
  if ( $level == 1 ) {
    $parser->{POD_HTMLEASY}->{INDEX}{p} = $parser->{POD_HTMLEASY}->{INDEX}{tree} ;
  }
  else {
    while ( $parser->{POD_HTMLEASY}->{INDEX}{l}{ $parser->{POD_HTMLEASY}->{INDEX}{p} } > ($level-1) ) {
      last if ! $parser->{POD_HTMLEASY}->{INDEX}{b}{ $parser->{POD_HTMLEASY}->{INDEX}{p} } ;
      $parser->{POD_HTMLEASY}->{INDEX}{p} = $parser->{POD_HTMLEASY}->{INDEX}{b}{ $parser->{POD_HTMLEASY}->{INDEX}{p} } ;
    }
  }
  
  my $array = [] ;
  
  $parser->{POD_HTMLEASY}->{INDEX}{l}{$array} = $level ;
  $parser->{POD_HTMLEASY}->{INDEX}{b}{$array} = $parser->{POD_HTMLEASY}->{INDEX}{p} ;
  
  push( @{$parser->{POD_HTMLEASY}->{INDEX}{p}} , $name , $array ) ;
  $parser->{POD_HTMLEASY}->{INDEX}{p} = $array ;

  
}

############
# VERBATIM #
############

sub verbatim { 
  my ($parser, $paragraph, $line_num) = @_;
  
  my $expansion = $parser->interpolate($paragraph, $line_num) ;
  
  $parser->{POD_HTMLEASY}->{VERBATIN_BUFFER} .= $expansion ;
}

sub _verbatim {
  my ( $parser ) = @_ ;
  
  my $output = $parser->output_handle() ;
  
  my $expansion = $parser->{POD_HTMLEASY}->{VERBATIN_BUFFER} ;
  $parser->{POD_HTMLEASY}->{VERBATIN_BUFFER} = '' ;
  
  _encode_entities($parser , \$expansion) ;
  _add_uri_href($parser , \$expansion) ;
  
  my $html = &{$parser->{POD_HTMLEASY}->{ON_VERBATIN}}($parser->{POD_HTMLEASY} , $expansion ) ;
  print $output $html if $html ne '' ;
}

#############
# TEXTBLOCK #
#############

sub textblock { 
  my ($parser, $paragraph, $line_num) = @_ ;
  
  _verbatim($parser) if $parser->{POD_HTMLEASY}->{VERBATIN_BUFFER} ne '' ;
  
  my $output = $parser->output_handle() ;
  my $expansion = $parser->interpolate($paragraph, $line_num) ;
  
  $expansion =~ s/\n[ \t]+\n/\n\n/gs ;
  $expansion =~ s/\s+$//gs ;
  
  _encode_entities($parser , \$expansion) ;
  _add_uri_href($parser , \$expansion) ;
  
  my $html = &{$parser->{POD_HTMLEASY}->{ON_TEXTBLOCK}}($parser->{POD_HTMLEASY} , $expansion ) ;
  print $output $html if $html ne '' ;
}

#####################
# INTERIOR_SEQUENCE #
#####################

sub interior_sequence { 
  my ($parser, $seq_command, $seq_argument) = @_ ;
  
  my $ret ;
  
  if ( $seq_command eq 'B' ) {
    _encode_entities($parser , \$seq_argument) ;
    _add_uri_href($parser , \$seq_argument) ;
    $ret = &{$parser->{POD_HTMLEASY}->{ON_B}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'C' ) {
    _encode_entities($parser , \$seq_argument) ;
    _add_uri_href($parser , \$seq_argument) ;
    $ret = &{$parser->{POD_HTMLEASY}->{ON_C}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'E' ) {
    $ret = &{$parser->{POD_HTMLEASY}->{ON_E}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'F' ) {
    $ret = &{$parser->{POD_HTMLEASY}->{ON_F}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'I' ) {
    _encode_entities($parser , \$seq_argument) ;
    _add_uri_href($parser , \$seq_argument) ;
    $ret = &{$parser->{POD_HTMLEASY}->{ON_I}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'L' ) {
    my ($text, $page, $section, $type) = &_parselink($seq_argument) ;
    $ret = &{$parser->{POD_HTMLEASY}->{ON_L}}($parser->{POD_HTMLEASY} , $seq_argument , $text, $page, $section, $type ) ;
  }
  elsif ( $seq_command eq 'S' ) {
    $ret = &{$parser->{POD_HTMLEASY}->{ON_S}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( $seq_command eq 'Z' ) {
    $ret = &{$parser->{POD_HTMLEASY}->{ON_Z}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  elsif ( defined $parser->{POD_HTMLEASY}->{"ON_\U$seq_command\E"} ) {
    $ret = &{$parser->{POD_HTMLEASY}->{"ON_\U$seq_command\E"}}($parser->{POD_HTMLEASY} , $seq_argument ) ;
  }
  else { $ret = "$seq_command<$seq_argument>" ;}
  
  $parser->{POD_HTMLEASY}{MARK_FILTER}{x}++ ;
  $parser->{POD_HTMLEASY}{MARK_FILTER}{  $parser->{POD_HTMLEASY}{MARK_FILTER}{x}  } = $ret ;
  $ret = "$parser->{POD_HTMLEASY}{MARK_FILTER}{MARK}#$parser->{POD_HTMLEASY}{MARK_FILTER}{x}#" ;
  
  return $ret ;
}

###########
# _ERRORS #
###########

sub _errors {
  my ($parser , $error) = @_ ;
  
  my $output = $parser->output_handle() ;
  
  $error =~ s/^\s*\**\s*errors?:?\s*//si ;
  $error =~ s/\s+$//s ;
  
  my $html = &{$parser->{POD_HTMLEASY}->{ON_ERROR}}($parser->{POD_HTMLEASY} , $error ) ;
  print $output $html if $html ne '' ;

  return 1 ;
}

#################
# _ADD_URI_HREF #
#################

sub _add_uri_href {
  my $parser = shift ;
  
  my $txt_ref ;
  if ( ref($_[0]) ) { $txt_ref = shift ;}
  else { my $txt = shift ; $txt_ref = \$txt ;}
  
  return $$txt_ref if $$txt_ref eq '' ;
  
  _mark_filter($parser , $txt_ref , qr/(<a\s+.*?href=(?:\S+|".*?"|'.*?')[^>]*>)/si) ;
  
  my %uri ;
  
  $$txt_ref =~ s/($MAIL_RE)/ $uri{ ++$uri{x} } = "mailto:$1" ; "#\0#PODHTML_URI#$uri{x}#"/gesx ;
  $$txt_ref =~ s/($URI_RE)/ $uri{ ++$uri{x} } = $1 ; "#\0#PODHTML_URI#$uri{x}#"/gesx ;

  delete $uri{x} ;
  foreach my $Key ( sort { $a <=> $b } keys %uri ) {
    $uri{$Key} = &{$parser->{POD_HTMLEASY}->{ON_URI}}($parser->{POD_HTMLEASY} , $uri{$Key} ) ;
  }
  
  $$txt_ref =~ s/\#\0\#PODHTML_URI\#(\d+)\#/
    $parser->{POD_HTMLEASY}{MARK_FILTER}{x}++ ;
    $parser->{POD_HTMLEASY}{MARK_FILTER}{  $parser->{POD_HTMLEASY}{MARK_FILTER}{x}  } = $uri{$1} ;
    "$parser->{POD_HTMLEASY}{MARK_FILTER}{MARK}#$parser->{POD_HTMLEASY}{MARK_FILTER}{x}#"
  /gesx if %uri ;
  
  return $$txt_ref ;
}

####################
# _ENCODE_ENTITIES #
####################

sub _encode_entities {
  my $parser = shift ;
  
  my $txt_ref ;
  if ( ref($_[0]) ) { $txt_ref = shift ;}
  else { my $txt = shift ; $txt_ref = \$txt ;}

  foreach my $Key ( @CHAR_2_ENTITY_ORDER ) {
    _mark_filter($parser , $txt_ref , qr/\Q$Key\E/s , $CHAR_2_ENTITY{$Key} ) ;
  }
  
  return $$txt_ref ;
}

################
# _MARK_FILTER #
################

sub _mark_filter {
  my ( $parser , $ref , $re , $val ) = @_ ;
  
  $$ref =~ s/($re)/
    $parser->{POD_HTMLEASY}{MARK_FILTER}{x}++ ;
    $parser->{POD_HTMLEASY}{MARK_FILTER}{  $parser->{POD_HTMLEASY}{MARK_FILTER}{x}  } = $val ? (ref($val) ? eval($$val) : $val) : $1 ;
    "$parser->{POD_HTMLEASY}{MARK_FILTER}{MARK}#$parser->{POD_HTMLEASY}{MARK_FILTER}{x}#"
  /gesx ;
  
}

#######################
# _REMOVE_MARK_FILTER #
#######################

sub _remove_mark_filter {
  my ( $parser , $ref ) = @_ ;
  1 while( $$ref =~ s/\Q$parser->{POD_HTMLEASY}{MARK_FILTER}{MARK}\E#(\d+)#/ delete $parser->{POD_HTMLEASY}{MARK_FILTER}{$1} /ges ) ; ## delete key to avoid recursion and a infinite loop.
  return 1 ;
}

##################
# _PARSE_SECTION #
##################

sub _parse_section {
  my ($link) = @_;
  $link =~ s/^\s+//s ;
  $link =~ s/\s+$//s ;

  return (undef, $1) if ($link =~ /^"\s*(.*?)\s*"$/s) ;

  my ($page, $section) = split (/\s*\/\s*/s, $link, 2) ;
  $section =~ s/^"\s*(.*?)\s*"$/$1/s if $section ;
  
  if ($page && $page =~ / /s && !defined ($section)) {
    $section = $page ;
    $page = undef ;
  }
  else {
    $page = undef unless $page ;
    $section = undef unless $section ;
  }
  
  return ($page, $section) ;
}

###############
# _INFER_TEXT #
###############

sub _infer_text {
  my ($page, $section) = @_ ;
  my $inferred;
  
  if ($page && !$section) {
    $inferred = $page;
  }
  elsif (!$page && $section) {
    $inferred = '"' . $section . '"' ;
  }
  elsif ($page && $section) {
    $inferred = '"' . $section . '" at ' . $page ;
  }
  
  return $inferred;
}

##############
# _PARSELINK #
##############

sub _parselink {
  my ($link) = @_;
  $link =~ s/\s+/ /g;

  my $text;

  if ($link =~ /\|/) {
    ($text, $link) = split (/\|/, $link, 2);
  }
  if ($link =~ /\A\w+:[^:\s]\S*\Z/) {
    my $inferred = $text || $link;
    $text = $inferred if (defined $inferred && !defined $text) ;
    return ($text, $link, undef, 'url');
  }
  
  my ($name, $section) = &_parse_section($link);
  my $inferred = $text || &_infer_text($name, $section);

  my $type = ($name && $name =~ /\(\S*\)/) ? 'man' : 'pod';

  $text = $inferred if (defined $inferred && !defined $text) ;
  return ($text, $name, $section, $type);
}

#######
# END #
#######

1;


