// pin specific hashes; default would pull armv5/armel image.
local stretch20200607armv7 =
  'debian@sha256:6aac188bc15bac908192685068ef8512a2e51b5eb1138b663e9e33d1d98ade4b';
local buster20200607armv7 =
  'debian@sha256:43e8691b4e25f4b0fd0f10bca8ea11b9f0578b0e5d2fe3b085290455dd07c0b6';

local configs = [{
  distro: 'debian',
  arch: 'amd64',
  versions: [
    { codename: 'buster', buildOn: 'buster', testOn: 'debian:buster-slim' },
    { codename: 'stretch', buildOn: 'buster', testOn: 'debian:stretch-slim' },
  ],
}, {
  distro: 'debian',
  arch: 'arm64',
  versions: [
    { codename: 'buster', buildOn: 'buster', testOn: 'debian:buster-slim' },
    { codename: 'stretch', buildOn: 'buster', testOn: 'debian:stretch-slim' },
  ],
}, {
  distro: 'debian',
  arch: 'arm',
  versions: [
    { codename: 'buster', buildOn: 'buster', testOn: buster20200607armv7 },
    { codename: 'stretch', buildOn: 'buster', testOn: stretch20200607armv7 },
  ],
}, {
  distro: 'ubuntu',
  arch: 'amd64',
  versions: [
    { codename: 'focal', buildOn: 'focal', testOn: 'ubuntu:focal' },
    { codename: 'bionic', buildOn: 'bionic', testOn: 'ubuntu:bionic' },
    { codename: 'xenial', buildOn: 'bionic', testOn: 'ubuntu:xenial' },
  ],
}];

local checks = {
  kind: 'pipeline',
  type: 'docker',
  name: 'checks',
  steps: [{
    name: 'jsonnet',
    image: 'bitnami/jsonnet:0.16.0',
    commands: [
      'jsonnetfmt .drone.jsonnet | diff -u .drone.jsonnet -',
      'jsonnet -y .drone.jsonnet | diff -u .drone.yml -',
    ],
  }],
};

local deb(version) = [{
  name: 'deb/%s' % version.codename,
  image: 'arescentral/deb-%s' % version.buildOn,
  settings: { dir: version.codename },
}, {
  name: 'check/%s' % version.codename,
  image: version.testOn,
  commands: [
    'uname -a',
    'dpkg -i gn_*%s_*.deb' % [version.codename],
    'gn --version',
  ],
}];

local publish(arch) = {
  name: 'publish',
  image: 'plugins/github-release',
  settings: {
    api_key: { from_secret: 'github_token' },
    files: ['gn_*.deb'] +
           if arch == 'amd64' then ['gn_*.dsc'] else [],
  },
  when: { event: 'tag' },
};

local debs(config) = {
  local distro = config.distro,
  local arch = config.arch,
  local versions = config.versions,

  kind: 'pipeline',
  type: 'docker',
  name: '%s/%s' % [distro, arch],
  depends_on: [checks.name],

  platform: {
    os: 'linux',
    arch: arch,
  },

  steps: std.flattenArrays([deb(version) for version in versions]) + [publish(arch)],
};

[checks] + [debs(config) for config in configs]
