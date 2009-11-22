#
# Copyright (c) 2008, Pawel J. Sawicki, pjs@pjs.name
#  
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#  
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# 

class duplicity::config {

	# Change it to the ids of both your signing and encrpting keys.
	$signing_key_id		= "SIGNING_KEY_ID"
	$encrypting_key_id	= "ENCRYPTING_KEY_ID"

	# Passphrase for the secret part of the key used to sign backups.
	$gpg_passphrase		= "PASSPHRASE"

	# Amazon S3 (http://s3.amazonaws.com/) credentials
	$aws_access_key_id	= "AWS_ACCESS_KEY_ID"
	$aws_secret_access_key	= "AWS_SECRET_ACCESS_KEY"

	# Prefix used for buckets at Amazon S3
	$s3_bucket_prefix	= "my-bucket-prefix-"

	include duplicity::config::gpg

	file { "/usr/local/sbin/duplicity-system-s3":
		content	=> template("duplicity/duplicity-system-s3.erb"),
		owner	=> "root",
		group	=> "root",
		mode	=> 0700,
	}

	cron { "duplicity-system-s3-full":
		ensure	=> present,
		command	=> "/usr/local/sbin/duplicity-system-s3 full 1> /dev/null",
		user	=> "root",
		minute	=> cron_rand(1, 60),
		hour	=> "3",
		weekday	=> "1"
	}

	cron { "duplicity-system-s3-incremental":
		ensure	=> present,
		command	=> "/usr/local/sbin/duplicity-system-s3 incremental 1> /dev/null",
		user	=> "root",
		minute	=> cron_rand(1, 60),
		hour	=> "3",
		weekday	=> "2-6"
	}
}

# Import keys used for signing and encrypting backups.
class duplicity::config::gpg {
	file { "/tmp/$signing_key_id.pub":
		owner => root,
		group => root,
		mode => 0600,
		source => "puppet:///duplicity/$signing_key_id.pub",
	}

	file { "/tmp/$signing_key_id.sec":
		owner => root,
		group => root,
		mode => 0600,
		source => "puppet:///duplicity/$signing_key_id.sec",
	}

	file { "/tmp/$encrypting_key_id.pub":
		owner => root,
		group => root,
		mode => 0600,
		source => "puppet:///duplicity/$encrypting_key_id.pub",
	}

	exec { "gpg --import /tmp/$signing_key_id.pub":
		unless => "gpg --list-key_ids $signing_key_id",
		user => root
	}

	exec { "gpg --import /tmp/$signing_key_id.sec":
		unless => "gpg --list-secret-key_ids $signing_key_id",
		user => root
	}

	exec { "gpg --import /tmp/$encrypting_key_id.pub":
		unless => "gpg --list-key_ids $encrypting_key_id",
		user => root
	}
}
