class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  class << self
    def inherited(subclass)
      super
      subclass.class_eval do
        setup_basic_api_documentation
      end
    end

    private
    def setup_basic_api_documentation
      [:index, :show, :create, :update, :delete].each do |api_action|
        swagger_api api_action do
          param :header, 'Authorization', :string, :required, 'Authentication token in the format of: Token token=<token>'
        end
      end
    end
  end

  before_action :authenticate

  protected

  def authenticate
    authenticate_token || render_unauthorized
  end

  def authenticate_token
    authenticate_with_http_token do |token, options|
      @current_user = User.find_by(api_key: token)
    end
  end

  def render_unauthorized(realm = "Application")
    self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
    render json: {error: "Bad Credentials"}, status: :unauthorized
  end
end
