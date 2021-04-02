class AddCompanyIds < ActiveRecord::Migration[6.1]
  def up

    #removed becouse of low disk space - running into PG::DiskFull: ERROR: could not extend file "base/16405/16458.5": No space left on device
    '

    #alter ov.or_podanie_issues
    execute "ALTER TABLE ov.or_podanie_issues
      ADD COLUMN company_id BIGINT,
      ADD FOREIGN KEY (company_id) REFERENCES ov.companies (cin);
      UPDATE ov.or_podanie_issues SET company_id = cin WHERE cin IS NOT NULL"

    #alter ov.likvidator_issues
    execute "ALTER TABLE ov.likvidator_issues
      ADD COLUMN company_id BIGINT,
      ADD FOREIGN KEY (company_id) REFERENCES ov.companies (cin);
      UPDATE ov.likvidator_issues SET company_id = cin WHERE cin IS NOT NULL"

    #alter ov.konkurz_vyrovnanie_issues
    execute "ALTER TABLE ov.konkurz_vyrovnanie_issues
      ADD COLUMN company_id BIGINT,
      ADD FOREIGN KEY (company_id) REFERENCES ov.companies (cin);
      UPDATE ov.konkurz_vyrovnanie_issues SET company_id = cin WHERE cin IS NOT NULL"

    #alter ov.znizenie_imania_issues
    execute "ALTER TABLE ov.znizenie_imania_issues
      ADD COLUMN company_id BIGINT,
      ADD FOREIGN KEY (company_id) REFERENCES ov.companies (cin);
      UPDATE ov.znizenie_imania_issues SET company_id = cin WHERE cin IS NOT NULL"

    #alter ov.konkurz_restrukturalizacia_issues
    execute "ALTER TABLE ov.konkurz_restrukturalizacia_issues
      ADD COLUMN company_id BIGINT,
      ADD FOREIGN KEY (company_id) REFERENCES ov.companies (cin);
      UPDATE ov.konkurz_restrukturalizacia_issues SET company_id = cin WHERE cin IS NOT NULL"
    
    '
  end

  def down
    '
    execute "ALTER TABLE ov.or_podanie_issues DROP COLUMN company_id;"
    execute "ALTER TABLE ov.likvidator_issues DROP COLUMN company_id;"
    execute "ALTER TABLE ov.konkurz_vyrovnanie_issues DROP COLUMN company_id;"
    execute "ALTER TABLE ov.znizenie_imania_issues DROP COLUMN company_id;"
    execute "ALTER TABLE ov.konkurz_restrukturalizacia_issues DROP COLUMN company_id;"
    '
  end
end
