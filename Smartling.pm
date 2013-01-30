
=head1 NAME

WebService::Smartling

=head1 AUTHOR

Matthew Cox <matt.cox@runkeeper.com>

=head1 SYNOPSIS

use WebService::Smartling;

my $sl = WebService::Smartling->new( param => { apiKey    => $KEY,
                                                projectId => $ID } )
  or die( "Unable to instantiate WebService::Smartling.$/" );

=head1 REQUIRES

L<strict>, L<warnings>, L<JSON>, L<Readonly>, L<Params::Validate>

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

This module provides a Perl wrapper around Smartling's 
( L<http://smartling.com> ) translation API.  You will need 
to be a Smartling customer and have your API Key and project Id
before you'll be able to do anything with this module.
=cut

package WebService::Smartling;
use base qw( WebService::Simple );

# these need to be outside the BEGIN
use strict;
use warnings;

binmode STDOUT, ":encoding(UTF-8)";

use JSON;
use Params::Validate qw( :all );
use Readonly;
#use Smart::Comments;
use version; our $VERSION = version->declare("v0.01");

__PACKAGE__->config(
    base_url        => "https://api.smartling.com/v1/",
    response_parser => { module => "JSON" },
    upload_url      => "https://api.smartling.com/v1/file/upload",
);

# Global patterns for param validation
Readonly our $REGEX_APIKEY => '^[A-Fa-f0-9-]{36}$';
Readonly our $REGEX_PROJID => '^[A-Fa-f0-9]{9}$';

Readonly our $REGEX_CONDITIONS => '^(haveAtLeastOneUnapproved|haveAtLeastOneApproved|haveAtLeastOneTranslated|haveAllTranslated|haveAllApproved|haveAllUnapproved)$';
Readonly our $REGEX_FILETYPES  => '^(android|ios|gettext|javaProperties|xliff|yaml)$';
Readonly our $REGEX_FILEURI    => '^\S+$';
Readonly our $REGEX_INT        => '^\d+$';
Readonly our $REGEX_RETYPE     => '^(pending|published|pseudo)$';
#Readonly our $REGEX_


=head1 INTERFACE

=head2 new

Inherited from L<WebService::Simple>, and takes all the same arguments. 
You B<must> provide the Smartling required arguments of B<apiKey> and 
B<projectId> in the param hash:

 my $sl = WebService::Smartling->new( param => { apiKey    => $KEY,
                                                 projectId => $ID } );

=over 4

=item B<Parameters>

=item apiKey B<(required)>

You can find within your Smartling project's dashboard: 
L<https://dashboard.smartling.com/settings/api>

=item projectId B<(required)>

You can find within your Smartling project's dashboard: 
L<https://dashboard.smartling.com/settings/api>

=back

=cut

my( %global_spec ) = (
  apiKey    => { type => SCALAR, regex => qr/$REGEX_APIKEY/, },
  projectId => { type => SCALAR, regex => qr/$REGEX_PROJID/, },
);

# only override this to force the passing of apiKey and projectId
sub new {
  my( $class, %args ) = @_;
  my $self = $class->SUPER::new(%args);
  
  # this is silly, but easier for validation
  my( @temp_params ) = %{ $self->{basic_params} };
  my %params = validate( @temp_params, \%global_spec );
  
  return bless($self, $class);
}

=head2 fileDelete(I<%params>)

Removes the file from Smartling. The file will no longer be available 
for download. Any complete translations for the file remain available 
for use within the system.

Smartling deletes files asynchronously and it typically takes a few 
minutes to complete. While deleting a file, you can not upload a file 
with the same fileUri.

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/delete%28DELETE%29>

=cut

my( %file_delete_spec ) = ( 
  fileUri => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
);

=over 4

=item B<Parameters>

=item fileUri B<(required)>

Value that uniquely identifies the file.

=item B<Returns: JSON result from API>

=over 4

 {"response":{"code":"SUCCESS","messages":[],"data":null,}}

=back

=back

=cut

sub fileDelete {
  my $self = shift();
  
  # validate
  my %params = validate( @_, \%file_delete_spec );
  
  # This code is essentially a simplified duplication of WebService::Simple->get 
  # with the HTTP method changed to delete
  my $uri = $self->request_url(
      url        => $self->base_url,
      extra_path => "file/delete",
      params     => { %{ $self->basic_params }, %params }
  );

  warn "Request URL is $uri$/" if $self->{debug};

  my @headers = @_;

  my $response = $self->SUPER::delete( $uri, @headers );
  if ( !$response->is_success ) {
      Carp::croak("request to $uri failed");
  }

  $response = WebService::Simple::Response->new_from_response(
      response => $response,
      parser   => $self->response_parser
  );
  
  return $response->parse_response;
}

=head2 fileGet(I<%params>)

Downloads the requested file from Smartling.

It is important to check the HTTP response status code. If Smartling 
finds and returns the file normally, you will receive a 200 SUCCESS 
response. If you receive any other response status code than 200, the 
requested file will not be part of the response.

When you upload a UTF-16 character encoded file, then /file/get requests 
for that file will have a character encoding of UTF-16. All other uploaded 
files will return with a character encoding of UTF-8. You can always use 
the content-type header in the response of a file/get request can always 
to determine the character encoding.

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/status%28GET%29>

=cut

my( %file_get_spec ) = ( 
  fileUri       => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
  locale        => { optional => 1, type => SCALAR, regex => qr/$REGEX_FILEURI/, },
  retrievalType => { optional => 1, type => SCALAR, regex => qr/$REGEX_RETYPE/, },
);

=over 4

=item B<Parameters>

=item fileUri B<(required)>

Value that uniquely identifies the file.

=item locale I<(optional)>

A locale identifier as specified in project setup. If no locale is 
specified, original content is returned. You can find the list of 
locales for your project on the Smartling dashboard at 
https://dashboard.smartling.com/settings/api.

=item retrievalType I<(optional)>

Allowed values: pending, published, pseudo

pending indicates that Smartling returns any translations (including 
non-published translations)

published indicates that Smartling returns only published translations

pseudo indicates that Smartling returns a modified version of the 
original text with certain characters transformed and the text expanded. 
For example, the uploaded string "This is a sample string", will return 
as "T~hís ~ís á s~ámpl~é str~íñg". Pseudo translations enable you to 
test how a longer string integrates into your application.

If you do not specify a value, Smartling assumes published.

=item B<Returns: HTTP::Common::Response object>

=over 4

 my( $dl ) = $sl->fileGet( { fileUri       => $uri,
                             locale        => 'fr-FR', 
                             retrievalType => 'pending' } );
 print $dl->content() . $/;

=back

=back

=cut

sub fileGet {
  my $self = shift;

  # validate
  my %params = validate( @_, \%file_get_spec );
  ### %params

  my $resp = $self->get( "file/get", \%params );
  return $resp;
}

=head2 fileList(I<%params>)

Lists recently uploaded files. Returns a maximum of 100 files.

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/list(GET)>

=cut

my( %file_list_spec ) = (
  fileTypes => { optional => 1, type => ARRAYREF, regex => qr/$REGEX_FILETYPES/, },
  locale    => { optional => 1, type => SCALAR, },
  uriMask   => { optional => 1, type => SCALAR, },
  lastUploadedAfter  => { optional => 1, type => SCALAR, },
  lastUploadedBefore => { optional => 1, type => SCALAR, },
  offset     => { optional => 1, type => SCALAR, regex => qr/$REGEX_INT/, },
  limit      => { optional => 1, type => SCALAR, regex => qr/$REGEX_INT/, },
  conditions => { optional => 1, type => ARRAYREF },
);

=over 4

=item B<Parameters>

=item locale I<(optional)>

If not specified, the Smartling Files API will return a listing of the 
original files matching the specified criteria. When the locale is not 
specified, completedStringCount will be "0".

=item uriMask I<(optional)>

SQL like syntax (ex '%.strings').

=item fileTypes I<(optional)>

Identifiers: android, ios, gettext, javaProperties, xliff, yaml. File 
types are combined using the logical ‘OR’.

=item lastUploadedAfter I<(optional)>

Return all files uploaded after the specified date. All dates will 
follow the common ISO 8601 date and time standard format, and will 
be expressed in UTC:

 "YYYY-MM-DDThh:mm:ss"

=item lastUploadedBefore I<(optional)>

Return all files uploaded before the specified date. All dates will 
follow the common ISO 8601 date and time standard format, and will 
be expressed in UTC:

 "YYYY-MM-DDThh:mm:ss"

=item offset I<(optional)>

For result set returns, the offset is a number indicating the distance
 from the beginning of the list; for example, for a result set of "50" 
 files, you can set the offset at 10 to return files 10 - 50.

=item limit I<(optional)>

For result set returns, limits the number of files returned; for 
example, for a result set of 50 files, a limit of "10" would return 
files 0 - 10.

=item conditions I<(optional)>

An array of the following conditions: haveAtLeastOneUnapproved, 
haveAtLeastOneApproved, haveAtLeastOneTranslated, haveAllTranslated, 
haveAllApproved, haveAllUnapproved. Conditions are combined using 
the logical 'OR'.

=item orderBy I<(optional)>

Choices: names of any return parameters; for example, fileUri, 
stringCount, wordCount, approvedStringCount, completedStringCount, 
lastUploaded and fileType. You can specify ascending or descending 
with each parameter by adding "_asc" or "_desc"; for example, 
"fileUri_desc". If you do not specify ascending or descending, 
the default is ascending.

=item B<Returns: JSON result from API>

=over 4

 {
   "fileCount": "[number]",
   "fileList" : [{
        "fileUri": "[/myproject/i18n/ui.properties]"
        "stringCount": "[number]",
        "wordCount": "[number]",
        "approvedStringCount": "[number]",
        "completedStringCount": "[number]",        
        "lastUploaded": "[YYYY-MM-DDThh:mm:ss]",    
        "fileType": "[fileType]" },
    { ... } ]
 }
 
=back

=back

=cut

sub fileList {
  my $self = shift;
  # validate
  my %params = validate( @_, \%file_list_spec );
  
  ### %params
  my $resp = $self->get( "file/list", \%params );
  return $resp->parse_response;
}

=head2 fileRename(I<%params>)

Renames an uploaded file by changing the fileUri. After renaming the 
file, the file will only be identified by the new fileUri you provide.

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/rename%28POST%29>

=over 4

=cut

my( %file_rename_spec ) = ( 
  fileUri    => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
  newFileUri => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
);
  
=item B<Parameters>

=item fileUri B<(required)>

Value that uniquely identifies the file to rename.

=item newFileUri B<(required)>

Value that uniquely identifies the new file. We recommend that you use 
file path + file name, similar to how version control systems identify 
the file. Example: /myproject/i18n/ui.properties.

This must be a fileUri that does not exist in the Smartling database.

=item B<Returns: JSON result from API>

=over 4

 {"response":{"code":"SUCCESS","messages":[],"data":null,}}
 
=back

=back

=cut


sub fileRename {
  my $self = shift;

  # validate
  my %params = validate( @_, \%file_rename_spec );
  ### %params

  my $resp = $self->post( "file/rename", \%params );
  return $resp->parse_response;
}

=head2 fileStatus(I<%params>)

Uploads original source content to Smartling (5MB limit), not translated 
files (other than importing .tmx files).

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/status%28GET%29>

=over 4

=cut

my( %file_status_spec ) = ( 
  fileUri => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
  locale  => { type => SCALAR, regex => qr/$REGEX_FILEURI/, },
);

=item B<Parameters>

=item fileUri B<(required)>

Value that uniquely identifies the file.

=item locale B<(required)>

A locale identifier as specified in project setup. You can find the 
list of locales for your project on the Smartling dashboard at 
https://dashboard.smartling.com/settings/api.

=item B<Returns: JSON result from API>

=over 4

 {

   "fileUri": "[/myproject/i18n/admin_ui.properties]",
   "stringCount": "[number]",
   "wordCount": "[number]",
   "approvedStringCount": "[number]",
   "completedStringCount": "[number]",  
   "lastUploaded": "[YYYY-MM-DDThh:mm:ss]",    
   "fileType": "[fileType]"
 }
 
fileUri - A unique identifier for the uploaded file.

stringCount - The number of strings in the uploaded file.

wordCount - The number of words in the uploaded file.

approvedStringCount - The number of strings in the uploaded file that 
are approved (available for translation).

completedStringCount - The number of strings in the uploaded file that 
are approved and translated.

lastUploaded - The time and date of the last upload: YYYY-MM-DDThh:mm:ss

fileType - The type of file: android, ios, gettext, javaProperties, xliff, yaml
 
=back

=back

=cut

sub fileStatus {
  my $self = shift;

  # validate
  my %params = validate( @_, \%file_status_spec );
  ### %params

  my $resp = $self->get( "file/status", \%params );
  return $resp->parse_response;
}

=head2 fileUpload(I<%params>)

Uploads original source content to Smartling (5MB limit), not translated 
files (other than importing .tmx files).

Refer to 
L<https://docs.smartling.com/display/docs/Files+API#FilesAPI-/file/upload(POST)>

=over 4

=cut

my( %file_upload_spec ) = ( 
  file     => { type      => SCALAR,
                callbacks => {
                  'readable file' => sub { -r shift() },
                  'less than 5MB' => sub { (sprintf( "%.2f", (-s shift()) / 1024 / 1024) < 5 ) },
                }
              },
  fileUri  => { optional => 1, type => SCALAR, regex => qr/$REGEX_FILEURI/, },
  fileType => { type => SCALAR, regex => qr/$REGEX_FILETYPES/, },
  approved => { optional => 1, type => SCALAR, },
  callbackUrl => { optional => 1, type => SCALAR, regex => qr/$REGEX_FILEURI/, },
);
  
=item B<Parameters>

=item file B<(required)>

The file contents to upload. This should be submitted via a 
multipart/form-data POST request.

=item fileUri B<(required)>

Value that uniquely identifies the uploaded file. This ID can be used 
to request the file back. We recommend you use file path + file name, 
similar to how version control systems identify the file. 
Example: /myproject/i18n/ui.properties.

=item approved I<(optional)>

This value, either true or false (default), determines whether content 
in the file is 'approved' (available for translation) upon submitting 
the file via the Smartling Dashboard. An error message will return if 
there are insufficient translation funds and approved is set to true.

=item fileType B<(required)>

Identifiers: android, ios, gettext, javaProperties, xliff, yaml

=item smartling.[command] I<(optional)>

Provides custom parser configuration for supported file types. See 
Supported File Types for more details.

=item callbackUrl I<(optional)>

Creates a callback to a URL when a file is 100% published for a locale. 
The callback includes these parameters: fileUri, locale If you upload 
another file without a callback URL, it will remove any previous 
callbackUrl for that file.

=item B<Returns: JSON result from API>

=over 4

 {
   "overWritten": "[true|false]"
   "stringCount": "[number]",
   "wordCount": "[number]"
 }
 
overWritten - Indicates whether the uploaded file has overwritten an 
existing file; either true or false.

stringCount - The number of strings in the uploaded file.

wordCount - The number of words in the uploaded file.
 
=back

=back

=cut

sub fileUpload( ) {
  my $self = shift;
  
  # this is the only way this works
  local $self->{base_url} = $self->config->{upload_url};
  
  # validate while adding the global params into the hash -- NEEDED FOR FORM POST BELOW
  my %params = ( %{ $self->{basic_params} }, 
                 %{ validate( @_, \%file_upload_spec ) }
                );

  if ( !defined( $params{fileUri} ) ) {
    $params{fileUri} = $params{file};
  }
  
  # the magical ArrayRef that tells HTTP::Request::Common to suck the file content
  $params{file} = [ $params{file} ];

  ### %params

  my $resp = $self->post( Content_Type => "form-data", Content => \%params );
  return $resp->parse_response;
}

=head2 projectLocaleList( )

Returns the enabled locales and identifiers for the project

Refer to L<https://docs.smartling.com/display/docs/Projects+API>

=over 4

=item B<Parameters>

B<none>

=item B<Returns: JSON result from API>

=over 4

 {
   "locales": [
       {
           "name": "Spanish",
           "locale": "es",
           "translated": "Español"
       },
       {
           "name": "French",
           "locale": "fr-FR",
           "translated": "Français"
       }
   ]
 }
 
locale - Locale identifier

name - Source locale name

translated - Localized locale name

=back

=back

=cut

sub projectLocaleList {
  my $self = shift;
  my $resp = $self->get( "project/locale/list" );
  return $resp->parse_response;
}

=head1 SEE ALSO

perl(1), L<WebService::Simple>, L<JSON>, L<HTTP::Common::Response>

=cut


1;
