class File < Sequel::Model

  plugin :validation_helpers

  def validate
    super
    validates_presence [:uploader, :name, :md5, :uploaded_at, :taken_down]
    validates_unique :md5
  end

end
