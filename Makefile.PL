use inc::Module::Install;
 
# Define metadata
name     'WebService-Smartling';
all_from 'lib/WebService/Smartling.pm';
version  '0.02';

# Specific dependencies
requires 'Carp';
requires 'JSON';
requires 'Params::Validate';
requires 'Readonly';
requires 'version';
requires 'WebService::Simple';

WriteAll;