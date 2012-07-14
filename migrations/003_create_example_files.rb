Sequel.migration do
  up do
    self[:uploads].insert(
      :user_id	    => 1,
      :name	    => "Example file.txt",
      :md5	    => "totally fake",
      :desc	    => "Does not exist.",
      :uploaded_at  => Time.now,
      :taken_down   => true
    )

    self[:uploads].insert(
      :user_id	    => 1,
      :name	    => "Fake",
      :md5	    => "nope",
      :desc	    => "Nada",
      :uploaded_at  => Time.now,
      :taken_down   => false
    )
  end

  down do
    self[:uploads].filter(:name => "Example file.txt").delete
    self[:uploads].filter(:name => "Fake").delete
  end
end

