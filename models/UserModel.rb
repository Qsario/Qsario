class User < Sequel::Model

  plugin :validation_helpers

  def validate
    super
    validates_presence [:name, :email, :password, :enabled, :takedowns, :admin, :joined_at]
    validates_unique(:name)  { |ds| ds.opts[:where].args.map! { |x| Sequel.function(:lower, x); ds } }
    validates_unique(:email) { |ds| ds.opts[:where].args.map! { |x| Sequel.function(:lower, x); ds } }
    validates_format /@/, :email, :message => 'is not a valid email'
  end

end
