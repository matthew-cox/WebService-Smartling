use inc::Module::Install;
 
# Define metadata
name           'WebService-Smartling';
all_from       'lib/WebService/Smartling.pm';

# Specific dependencies
requires 'Carp';
requires 'JSON';
requires 'Params::Validate';
requires 'Readonly';
requires 'version';

WriteAll;