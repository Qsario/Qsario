Sequel.migration do

  change do
    create_table(:users) do
      primary_key :id,		      :type => Bignum
      String	  :name,	      :null => false, :size	=> 25,	  :unique => true
      String	  :email,	      :null => false, :size	=> 50,	  :unique => true
      String	  :password,	      :null => false, :size	=> 100
      Fixnum	  :takedowns,	      :null => false, :default	=> 0
      TrueClass	  :enabled,	      :null => false, :default  => true
      FalseClass  :admin,	      :null => false, :default	=> false
      DateTime	  :joined_at,	      :null => false
      constraint(:name_min_length) { :char_length.sql_function(:name) > 2 }
    end

    create_table(:uploads) do
      primary_key :id,		      :type => Bignum
      foreign_key :user_id,	      :users
      String	  :name,	      :null => false, :size	=> 100
      String	  :md5,		      :null => false, :size	=> 35,	  :unique => true
      String	  :desc,	      :null => true,  :text	=> true
      DateTime	  :uploaded_at,	      :null => false
      FalseClass  :taken_down,	      :null => false, :default	=> false
    end

    create_join_table(:user_id => :users, :upload_id => :uploads)

  end
end
