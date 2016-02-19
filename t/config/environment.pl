use File::Spec;

my $data_dir = File::Spec->catdir(
    substr(__FILE__, 0, rindex(__FILE__, "config")),
    'data');

return {
    'dev.foo.overlay.dir' => $data_dir,
}
