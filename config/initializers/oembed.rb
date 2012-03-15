require 'oembed'
require 'uri'

#
# SECURITY NOTICE! CROSS-SITE SCRIPTING!
# these endpoints may inject html code into our page
# note that 'trusted_endpoint_url' is the only information
# in OEmbed that we can trust. anything else may be spoofed!

OEmbed::Providers::Cubbies = OEmbed::Provider.new("http://cubbi.es/oembed")
# This provider won't work without specifying at least one supported URL scheme.
# e.g. OEmbed::Providers::Cubbies << "http://cubbi.es/*"
OEmbed::Providers::VimeoSSL = OEmbed::Provider.new("https://vimeo.com/api/oembed.{format}")
OEmbed::Providers::VimeoSSL << "http://*.vimeo.com/*"
OEmbed::Providers::VimeoSSL << "https://*.vimeo.com/*"

oembed_provider_list = [
  OEmbed::Providers::Youtube,
  OEmbed::Providers::VimeoSSL,
  OEmbed::Providers::Flickr,
  OEmbed::Providers::SoundCloud,
  OEmbed::Providers::Cubbies,
]

SECURE_ENDPOINTS = oembed_provider_list.map do |provider|
  OEmbed::Providers.register(provider)
  provider.endpoint
end

OEmbed::Providers.register_fallback(OEmbed::ProviderDiscovery)

TRUSTED_OEMBED_PROVIDERS = OEmbed::Providers
