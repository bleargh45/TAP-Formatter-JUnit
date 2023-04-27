requires 'perl', '>= 5.010';
requires 'File::Slurp';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'namespace::clean';
requires 'TAP::Harness', '>= 3.12';
requires 'XML::Generator';

test_requires 'IO::Scalar';
test_requires 'IPC::Run';
test_requires 'Test::More', '>= 0.96';
test_requires 'Test::XML';
test_requires 'version';

on 'develop' => sub {
  requires 'Dist::Zilla::PluginBundle::Author::GTERMARS', '>= 0.04';
};
