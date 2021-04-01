class CreateCompanies < ActiveRecord::Migration[6.1]

  #migration
  def up
    #create table
    execute "CREATE TABLE ov.companies(
      cin BIGINT NOT NULL PRIMARY KEY,
      name CHARACTER VARYING,
      br_section CHARACTER VARYING,
      address_line CHARACTER VARYING,
      last_update TIMESTAMP WITHOUT TIME ZONE,
      created_at TIMESTAMP WITHOUT TIME ZONE,
      updated_at TIMESTAMP WITHOUT TIME ZONE
      );"

    #fill in from ov.or_podanie_issues
    execute "WITH rows AS (
        SELECT cin, 
        corporate_body_name AS name, 
        br_section, 
        address_line, 
        updated_at, 
        ROW_NUMBER() OVER(
          PARTITION BY cin 
          ORDER BY updated_at DESC
        ) AS row_num 
        FROM ov.or_podanie_issues 
        WHERE cin IS NOT NULL
      ) 
      INSERT INTO ov.companies(
        cin,
        name, 
        br_section,
        address_line,
        last_update,
        created_at,
        updated_at
      )(
        SELECT
          cin,
          name, 
          br_section,
          address_line,
          updated_at,
          NOW(),
          NOW()    
        FROM rows 
        WHERE row_num = 1
      );"

    #fill in from ov.likvidator_issues
    execute "WITH rows AS (
        SELECT cin, 
        corporate_body_name AS name, 
        br_section, 
        updated_at, 
        ROW_NUMBER() OVER(
          PARTITION BY cin 
          ORDER BY updated_at DESC
        ) AS row_num,
        street AS a,
        postal_code AS b,
        city AS c 
        FROM ov.likvidator_issues 
        WHERE cin IS NOT NULL
      ) 
      INSERT INTO ov.companies(
        cin,
        name, 
        br_section,
        address_line,
        last_update,
        created_at,
        updated_at
      )(
        SELECT
          cin,
          name, 
          br_section,
          CONCAT(a, ', ', b, ' ',c),
          updated_at,
          NOW(),
          NOW()    
        FROM rows 
        WHERE row_num = 1 
              AND NOT EXISTS (SELECT cin FROM ov.companies WHERE cin = rows.cin)
      );"

    #fill in from ov.konkurz_vyrovnanie_issues
    execute "WITH rows AS (
        SELECT cin, 
        corporate_body_name AS name,
        updated_at, 
        ROW_NUMBER() OVER(
          PARTITION BY cin 
          ORDER BY updated_at DESC
        ) AS row_num,
        street AS a,
        postal_code AS b,
        city AS c 
        FROM ov.konkurz_vyrovnanie_issues 
        WHERE cin IS NOT NULL
      ) 
      INSERT INTO ov.companies(
        cin,
        name, 
        br_section,
        address_line,
        last_update,
        created_at,
        updated_at
      )(
        SELECT
          cin,
          name, 
          '',
          CONCAT(a, ', ', b, ' ',c),
          updated_at,
          NOW(),
          NOW()    
        FROM rows 
        WHERE row_num = 1 
              AND NOT EXISTS (SELECT cin FROM ov.companies WHERE cin = rows.cin)
      );"

    #fill in from ov.znizenie_imania_issues
    execute "WITH rows AS (
        SELECT cin, 
        corporate_body_name AS name, 
        br_section, 
        updated_at, 
        ROW_NUMBER() OVER(
          PARTITION BY cin 
          ORDER BY updated_at DESC
        ) AS row_num,
        street AS a,
        postal_code AS b,
        city AS c 
        FROM ov.znizenie_imania_issues 
        WHERE cin IS NOT NULL
      ) 
      INSERT INTO ov.companies(
        cin,
        name, 
        br_section,
        address_line,
        last_update,
        created_at,
        updated_at
      )(
        SELECT
          cin,
          name, 
          br_section,
          CONCAT(a, ', ', b, ' ',c),
          updated_at,
          NOW(),
          NOW()    
        FROM rows 
        WHERE row_num = 1 
              AND NOT EXISTS (SELECT cin FROM ov.companies WHERE cin = rows.cin)
      );"

    #fill in from ov.konkurz_restrukturalizacia_actors
    execute "WITH rows AS (
        SELECT cin, 
        corporate_body_name AS name,
        updated_at, 
        ROW_NUMBER() OVER(
          PARTITION BY cin 
          ORDER BY updated_at DESC
        ) AS row_num,
        street AS a,
        postal_code AS b,
        city AS c 
        FROM ov.konkurz_restrukturalizacia_actors 
        WHERE cin IS NOT NULL
      ) 
      INSERT INTO ov.companies(
        cin,
        name, 
        br_section,
        address_line,
        last_update,
        created_at,
        updated_at
      )(
        SELECT
          cin,
          name, 
          '',
          CONCAT(a, ', ', b, ' ',c),
          updated_at,
          NOW(),
          NOW()    
        FROM rows 
        WHERE row_num = 1 
              AND NOT EXISTS (SELECT cin FROM ov.companies WHERE cin = rows.cin)
      );"
  end

  #revert migration
  def down
    execute "DROP TABLE ov.companies"
  end
end
