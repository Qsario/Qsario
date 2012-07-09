Sequel.migration do
  # Initialize the site DB by creating an account for myself.
  change do
    self[:users].insert(
      # The password is just a hash and  I will change it immediately.
      :name	    => 'Qsario',
      :email	    => 'mvenzke+qsario@gmail.com',
      :password	    => '00516a8bZCqpDfCw4HOdYAqXF0D74UzrFJYNKiba6d6fd049b7f58da15703e4c3e3ec776d8535371d103e994df9114d',
      :enabled	    => true,
      :admin	    => true,
      :joined_at    => Time.now
    )
  end
end
