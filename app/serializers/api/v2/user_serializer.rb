module Api::V2
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :email, :api_key, :active
  end
end
