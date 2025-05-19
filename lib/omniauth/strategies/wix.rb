require 'omniauth/strategies/oauth2'

module OmniAuth
  module Strategies
    class Wix < OmniAuth::Strategies::OAuth2
      option :name, 'wix'

      option :client_options, {
        :authorize_url => 'https://www.wix.com/installer/install',
        :token_url => 'https://www.wix.com/oauth/access.json'
      }

      option :provider_ignores_state, true

      uid { request.params["instanceId"] }

      credentials do
        hash = {"token" => access_token.token}
        hash["refresh_token"] = access_token.refresh_token if access_token.refresh_token
        hash["expires_at"] = access_token.expires_at if access_token.expires?
        hash["expires"] = access_token.expires?
        hash
      end
      
      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options)) do |b|
          b.request :json
          b.adapter Faraday.default_adapter
        end
      end

      def authorize_params
        super.tap do |params|
          params["redirectUrl"] = callback_url
          params["appId"] = options[:client_id]
          params["token"] = request.params["token"]
        end
      end
      
      def callback_url
        full_host + script_name + ENV["WIX_CALLBACK_PATH"]
      end

      def build_access_token
        verifier = request.params["code"]
        params = { :redirect_uri => callback_url }.merge(token_params.to_hash(:symbolize_keys => true).merge({ headers: { 'Content-Type' => 'application/json' } }))
        client.auth_code.get_token(verifier, params, deep_symbolize(options.auth_token_params))
      end
    end
  end
end
