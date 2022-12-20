# @summary Configuration of samba shares
#
class profile::app::samba::shares {

  samba::share { 'media':
    path    => '/srv/media',
    options => {
      'comment'        => 'Media Server Share',
      'create mask'    => '0664',
      'directory mask' => '0775',
      'writeable'      => '1',
      'guest ok'       => '1',
    },
  }

  samba::share { 'users':
    path    => '/home',
    mode    => '0755',
    options => {
      'comment'                   => 'Private user folder',
      'read only'                 => 'No',
      'browseable'                => 'yes',
      'create mask'               => '0775',
      'directory mask'            => '0775',
      # shadow_copy2 acl_xattr needed for windows',
      # remainder needed for MacOS',
      'vfs objects'               => 'shadow_copy2 streams_xattr acl_xattr catia',
      'shadow:format'             => 'zfs-auto-snap_%S-%Y-%m-%d-%H%M',
      'shadow:localtime'          => 'no',
      'shadow:snapdirseverywhere' => 'yes',
      'shadow:snapdir'            => '.zfs/snapshot',
      'shadow:sort'               => 'desc',
      'root preexec'              => "bash -c '[[ -d /home/%U ]] || mkdir -m 0700 /home/%U && chown %U:\"Domain Users\" /home/%U'",
      # Not sure about these!',
      'acl group control'         => 'yes',
      'inherit permissions'       => 'yes',
    },
  }

  samba::share { 'virtual':
    path    => '/srv/virtual',
    options => {
      'read only'      => 'no',
      'create mask'    => '0775',
      'directory mask' => '0775',
    },
  }

  samba::share { 'backup':
    path    => '/srv/backup',
    options => {
      'comment'        => '"Backup Share"',
      'oplocks'        => '1',
      'create mask'    => '0664',
      'directory mask' => '0775',
      'writeable'      => '1',
      'guest ok'       => '1',
    },
  }

  samba::share { 'public':
    path    => '/srv/public',
    options => {
      'create mask'    => '0664',
      'directory mask' => '0775',
      'writeable'      => '1',
      'guest ok'       => '1',
    },
  }

  samba::share { 'srv':
    path    => '/srv',
    options => {
      'writeable' => '1',
    },
  }

# TODO: these shares used to be for humax access - are they still needed
  samba::share { 'Films':
    path    => '/srv/media/content/films',
    options => {
      'writeable'      => '1',
      'create mask'    => '0775',
      'directory mask' => '0775',
    },
  }

  samba::share { 'TV':
    path    => '/srv/media/content/tv',
    options => {
      'writeable'      => '1',
      'create mask'    => '0775',
      'directory mask' => '0775',
    },
  }

}
