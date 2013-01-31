# NAME

WebService::Smartling - The great new WebService::Smartling!

# VERSION

Version 0.01

# SYNOPSIS

This module provides a Perl wrapper around Smartling's 
( [http://smartling.com](http://smartling.com) ) translation API.  You will need 
to be a Smartling customer and have your API Key and project Id
before you'll be able to do anything with this module.

__Note:__ Some parameter validation is purposely lax. The API will 
generally fail when invalid params are passed. The errors are not 
helpful.

# INTERFACE

## new

Inherited from [WebService::Simple](http://search.cpan.org/perldoc?WebService::Simple), and takes all the same arguments. 
You __must__ provide the Smartling required arguments of __apiKey__ and 
__projectId__ in the param hash:

    my $sl = WebService::Smartling->new( param => { apiKey    => $KEY,
                                                    projectId => $ID } );

__Note:__ Enabling debug mode will change the API end point to the
Smartling Sandbox API. This is an excellent way to debug your API
interactions without affecting your production project.

    my $sl = WebService::Smartling->new( param => { apiKey    => $KEY,
                                                    projectId => $ID },
                                         debug => 1 );

- __Parameters__
- apiKey __(required)__

    You can find within your Smartling project's dashboard: 
    [https://dashboard.smartling.com/settings/api](https://dashboard.smartling.com/settings/api)

- projectId __(required)__

    You can find within your Smartling project's dashboard: 
    [https://dashboard.smartling.com/settings/api](https://dashboard.smartling.com/settings/api)

## fileDelete(_%params_)

Removes the file from Smartling. The file will no longer be available 
for download. Any complete translations for the file remain available 
for use within the system.

Smartling deletes files asynchronously and it typically takes a few 
minutes to complete. While deleting a file, you can not upload a file 
with the same fileUri.

Refer to 
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/delete%28DELETE%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/delete%28DELETE%29)

- __Parameters__
- fileUri __(required)__

    Value that uniquely identifies the file.

- __Returns: JSON result from API__

            {"response":{"code":"SUCCESS","messages":[],"data":null,}}

## fileGet(_%params_)

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
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/status%28GET%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/status%28GET%29)

- __Parameters__
- fileUri __(required)__

    Value that uniquely identifies the file.

- locale _(optional)_

    A locale identifier as specified in project setup. If no locale is 
    specified, original content is returned. You can find the list of 
    locales for your project on the Smartling dashboard at 
    https://dashboard.smartling.com/settings/api.

- retrievalType _(optional)_

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

- __Returns: HTTP::Common::Response object__

            my( $dl ) = $sl->fileGet( { fileUri       => $uri,
                                        locale        => 'fr-FR', 
                                        retrievalType => 'pending' } );
            print $dl->content() . $/;

## fileList(_%params_)

Lists recently uploaded files. Returns a maximum of 100 files.

Refer to 
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/list%28GET%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/list%28GET%29)

- __Parameters__
- locale _(optional)_

    If not specified, the Smartling Files API will return a listing of the 
    original files matching the specified criteria. When the locale is not 
    specified, completedStringCount will be "0".

- uriMask _(optional)_

    SQL like syntax (ex '%.strings').

- fileTypes _(optional)_

    Identifiers: android, ios, gettext, javaProperties, xliff, yaml. File 
    types are combined using the logical ‘OR’.

- lastUploadedAfter _(optional)_

    Return all files uploaded after the specified date. All dates will 
    follow the common ISO 8601 date and time standard format, and will 
    be expressed in UTC:

        "YYYY-MM-DDThh:mm:ss"

- lastUploadedBefore _(optional)_

    Return all files uploaded before the specified date. All dates will 
    follow the common ISO 8601 date and time standard format, and will 
    be expressed in UTC:

        "YYYY-MM-DDThh:mm:ss"

- offset _(optional)_

    For result set returns, the offset is a number indicating the distance
     from the beginning of the list; for example, for a result set of "50" 
     files, you can set the offset at 10 to return files 10 - 50.

- limit _(optional)_

    For result set returns, limits the number of files returned; for 
    example, for a result set of 50 files, a limit of "10" would return 
    files 0 - 10.

- conditions _(optional)_

    An array of the following conditions: haveAtLeastOneUnapproved, 
    haveAtLeastOneApproved, haveAtLeastOneTranslated, haveAllTranslated, 
    haveAllApproved, haveAllUnapproved. Conditions are combined using 
    the logical 'OR'.

- orderBy _(optional)_

    Choices: names of any return parameters; for example, fileUri, 
    stringCount, wordCount, approvedStringCount, completedStringCount, 
    lastUploaded and fileType. You can specify ascending or descending 
    with each parameter by adding "\_asc" or "\_desc"; for example, 
    "fileUri\_desc". If you do not specify ascending or descending, 
    the default is ascending.

- __Returns: JSON result from API__

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

## fileRename(_%params_)

Renames an uploaded file by changing the fileUri. After renaming the 
file, the file will only be identified by the new fileUri you provide.

Refer to 
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/rename%28POST%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/rename%28POST%29)

- __Parameters__
- fileUri __(required)__

    Value that uniquely identifies the file to rename.

- newFileUri __(required)__

    Value that uniquely identifies the new file. We recommend that you use 
    file path + file name, similar to how version control systems identify 
    the file. Example: /myproject/i18n/ui.properties.

    This must be a fileUri that does not exist in the Smartling database.

- __Returns: JSON result from API__

            {"response":{"code":"SUCCESS","messages":[],"data":null,}}

## fileStatus(_%params_)

Uploads original source content to Smartling (5MB limit), not translated 
files (other than importing .tmx files).

Refer to 
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/status%28GET%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/status%28GET%29)

- __Parameters__
- fileUri __(required)__

    Value that uniquely identifies the file.

- locale __(required)__

    A locale identifier as specified in project setup. You can find the 
    list of locales for your project on the Smartling dashboard at 
    https://dashboard.smartling.com/settings/api.

- __Returns: JSON result from API__

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

            approvedStringCount - The number of strings in the uploaded file that are approved (available for translation).

            completedStringCount - The number of strings in the uploaded file that are approved and translated.

            lastUploaded - The time and date of the last upload: YYYY-MM-DDThh:mm:ss

            fileType - The type of file: android, ios, gettext, javaProperties, xliff, yaml
            

## fileUpload(_%params_)

Uploads original source content to Smartling (5MB limit), not translated 
files (other than importing .tmx files).

Refer to 
[https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/upload%28POST%29](https://docs.smartling.com/display/docs/Files+API\#FilesAPI-/file/upload%28POST%29)

- __Parameters__
- file __(required)__

    The file contents to upload. This should be submitted via a 
    multipart/form-data POST request.

- fileUri __(required)__

    Value that uniquely identifies the uploaded file. This ID can be used 
    to request the file back. We recommend you use file path + file name, 
    similar to how version control systems identify the file. 
    Example: /myproject/i18n/ui.properties.

- approved _(optional)_

    This value, either true or false (default), determines whether content 
    in the file is 'approved' (available for translation) upon submitting 
    the file via the Smartling Dashboard. An error message will return if 
    there are insufficient translation funds and approved is set to true.

- fileType __(required)__

    Identifiers: android, ios, gettext, javaProperties, xliff, yaml

- smartling.\[command\] _(optional)_

    Provides custom parser configuration for supported file types. See 
    Supported File Types for more details.

- callbackUrl _(optional)_

    Creates a callback to a URL when a file is 100% published for a locale. 
    The callback includes these parameters: fileUri, locale If you upload 
    another file without a callback URL, it will remove any previous 
    callbackUrl for that file.

- __Returns: JSON result from API__

            {
              "overWritten": "[true|false]"
              "stringCount": "[number]",
              "wordCount": "[number]"
            }

            overWritten - Indicates whether the uploaded file has overwritten an existing file; either true or false.

            stringCount - The number of strings in the uploaded file.

            wordCount - The number of words in the uploaded file.

## projectLocaleList( )

Returns the enabled locales and identifiers for the project

Refer to [https://docs.smartling.com/display/docs/Projects+API](https://docs.smartling.com/display/docs/Projects+API)

- __Parameters__

    __none__

- __Returns: JSON result from API__

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

# AUTHOR

Matthew Cox, `<coxmat+cpan at gmail.com>`

# BUGS

Please report any bugs or feature requests to `bug-webservice-smartling at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Smartling](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Smartling).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Smartling



You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Smartling](http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Smartling)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/WebService-Smartling](http://annocpan.org/dist/WebService-Smartling)

- CPAN Ratings

    [http://cpanratings.perl.org/d/WebService-Smartling](http://cpanratings.perl.org/d/WebService-Smartling)

- Search CPAN

    [http://search.cpan.org/dist/WebService-Smartling/](http://search.cpan.org/dist/WebService-Smartling/)

# SEE ALSO

perl(1), [WebService::Simple](http://search.cpan.org/perldoc?WebService::Simple), [JSON](http://search.cpan.org/perldoc?JSON), [HTTP::Common::Response](http://search.cpan.org/perldoc?HTTP::Common::Response)

# LICENSE AND COPYRIGHT

Copyright 2013 Matthew Cox.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


