module Api::V2
  class TaskSerializer < ActiveModel::Serializer
    attributes :id, :name, :points, :active
  end
end
