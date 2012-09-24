class User < Sequel::Model

  plugin :validation_helpers

  one_to_many :uploads

  def before_create
    super
    self.enabled ||= true
    self.joined_at ||= Time.now
    self.takedowns ||= 0
    # Note that the default value of admin is false (c.f. the 001_ migration).
    # this is only here as a failsafe to guard against accidents.
    self.admin = false
  end

  def validate
    super
    validates_presence [:name, :email, :password, :enabled, :takedowns, :admin, :joined_at]
    validates_unique(:name)  { |ds| ds.opts[:where].args.map! { |x| Sequel.function(:lower, x); ds } }
    validates_unique(:email) { |ds| ds.opts[:where].args.map! { |x| Sequel.function(:lower, x); ds } }
    validates_format /@/, :email, :message => 'is not a valid email'
  end

end
