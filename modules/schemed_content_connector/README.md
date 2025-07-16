In this first version, executes a jsonpath against a toml file returning the result as a string:

bal run -- <toml_file> \<jsonpath>

Take care the toml file to have the .toml extension, as next versions of this package will deduct the content type in the file from its extension.