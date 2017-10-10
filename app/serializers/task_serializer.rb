class TaskSerializer < ActiveModel::Serializer
  attributes :id, :name, :points, :active
end
