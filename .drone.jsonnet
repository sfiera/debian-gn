local arches = ['amd64', 'arm', 'arm64'];

local testImage = {
  amd64: 'ubuntu:trusty',
  arm64: 'debian:stretch-slim',

  // debian:stretch-slim armv7; default would pull armv5/armel image.
  arm: 'debian@sha256:6aac188bc15bac908192685068ef8512a2e51b5eb1138b663e9e33d1d98ade4b',
};

[{
  kind: 'pipeline',
  type: 'docker',
  name: arch,

  platform: {
    os: 'linux',
    arch: arch,
  },

  steps: [{
    name: 'uname',
    image: testImage[arch],
    commands: ['uname -a'],
  }, {
    name: 'dist',
    image: 'python:3.8-alpine',
    commands: ['scripts/download-dist'],
  }, {
    name: 'deb',
    image: 'arescentral/deb',
  }, {
    name: 'check',
    image: testImage[arch],
    commands: [
      'dpkg -i gn_*.deb',
      'gn --version',
    ],
  }, {
    name: 'publish',
    image: 'plugins/github-release',
    settings: {
      api_key: { from_secret: 'github_token' },
      files: [
        '*.deb',
        '*.dsc',
      ],
    },
    when: { event: 'tag' },
  }],
} for arch in arches]
