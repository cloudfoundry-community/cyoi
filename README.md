Choose Your Own Infrastructure
==============================

A library to ask an end-user to choose an infrastructure (AWS, OpenStack, etc), region, and login credentials.

This library was extracted from [inception-server](https://github.com/drnic/inception-server) for reuse by [bosh-bootstrap](https://github.com/StarkAndWayne/bosh-bootstrap). It might also be useful to your own CLI applications that need to ask a user to give you their infrastructure credentials/region so your application can control their infrastructure (say via [fog](http://fog.io)).

[![Build Status](https://travis-ci.org/cloudfoundry-community/cyoi.png?branch=master)](https://travis-ci.org/cloudfoundry-community/cyoi)[![Code Climate](https://codeclimate.com/github/cloudfoundry-community/cyoi.png)](https://codeclimate.com/github/cloudfoundry-community/cyoi)

When you use the library, your application will attempt to guess what infrastructure/credentials the user will use (via `~/.fog`) and then fall back to prompting for remaining information:

```
Auto-detected infrastructure API credentials at ~/.fog (override with $FOG)
1. AWS (default)
2. AWS (starkandwayne)
3. Alternate credentials
Choose infrastructure:  3

1. AWS
2. OpenStack
Choose infrastructure:  1


Using provider aws:

1. *US East (Northern Virginia) Region (us-east-1)
2. US West (Oregon) Region (us-west-2)
3. US West (Northern California) Region (us-west-1)
4. EU (Ireland) Region (eu-west-1)
5. Asia Pacific (Singapore) Region (ap-southeast-1)
6. Asia Pacific (Sydney) Region (ap-southeast-2)
7. Asia Pacific (Tokyo) Region (ap-northeast-1)
8. South America (Sao Paulo) Region (sa-east-1)
Choose AWS region: 2

Access key: KEYGOESHERE
Secret key: SECRETGOESHERE

Confirming: Using aws/us-west-2
```

Usage
-----

```ruby
provider_cli = Cyoi::Cli::Provider.new([settings_dir])
provider_cli.execute!
settings = YAML.load_file(File.join(settings_dir, "settings.yml"))

settings["provider"]["name"] # aws, openstack
settings["provider"]["region"] # us-east-1
settings["provider"]["credentials"] # aws or openstack URLs & credentials
```

Installation
------------

To use as a stand-alone CLI, install the rubygem:

```
$ gem install cyoi
```

To use it as a library within your own application, add this line to your application's Gemfile:

```
gem "cyoi"
```

Contributing
------------

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. Send [@drnic](https://github.com/drnic) a big bag of Doritos
