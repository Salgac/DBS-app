class CreateCompanies < ActiveRecord::Migration[6.1]

  #migration
  def up
    #create table
    execute "CREATE TABLE ov.companies(
      cin BIGINT NOT NULL PRIMARY KEY,
      name CHARACTER VARYING,
      br_section CHARACTER VARYING,
      adress_line CHARACTER VARYING,
      last_update TIMESTAMP WITHOUT TIME ZONE,
      created_at TIMESTAMP WITHOUT TIME ZONE,
      updated_at TIMESTAMP WITHOUT TIME ZONE
      );"

    #fill in from ov.or_podanie_issues
    #fill in from ov.likvidator_issues
    #fill in from ov.konkurz_vyrovnanie_issues
    #fill in from ov.znizenie_imania_issues
    #fill in from ov.konkurz_restrukturalizacia_actors
  end

  #revert migration
  def down
    execute "DROP TABLE ov.companies"
  end
end
