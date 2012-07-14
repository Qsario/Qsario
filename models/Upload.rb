class Upload < Sequel::Model

  plugin :validation_helpers

  many_to_one :users

  def before_create
    self.uploaded_at ||= Time.now
    super
  end

  def before_update
    self.md5.downcase!	# Just making sure.
    super
  end

  def validate
    super
    validates_presence [:uploader, :name, :md5, :uploaded_at, :taken_down]
    validates_unique :md5
  end

end
