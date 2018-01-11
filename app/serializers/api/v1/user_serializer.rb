module Api::V1  
  class UserSerializer < ActiveModel::Serializer
    attributes :id, :email, :api_key, :active
  end
end
