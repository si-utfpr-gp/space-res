class BaseForm
  include ActiveModel::Model

  def self.model_name
    ActiveModel::Name.new(self, nil, model_name_name)
  end

  def self.model_name_name
    name.demodulize.sub(/Form$/, "")
  end
end
