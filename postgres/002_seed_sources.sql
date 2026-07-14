-- Sprint 1 seed data: normalized source categories and Libyan government entities.
-- Social networks are intentionally excluded from Sprint 1.

INSERT INTO source_categories (name, description) VALUES
  ('Executive', 'Executive sources'),
  ('Legislature', 'Legislature sources'),
  ('Judiciary', 'Judiciary sources'),
  ('Economy', 'Economy sources'),
  ('Energy', 'Energy sources'),
  ('Security', 'Security sources'),
  ('Health', 'Health sources'),
  ('Education', 'Education sources'),
  ('Infrastructure', 'Infrastructure sources'),
  ('Transport', 'Transport sources'),
  ('Local Government', 'Local Government sources'),
  ('Regulator', 'Regulator sources'),
  ('Audit', 'Audit sources'),
  ('Elections', 'Elections sources'),
  ('Culture', 'Culture sources')
ON CONFLICT (name) DO NOTHING;

WITH entity_seed(name_en, slug, category_name, website_url, priority) AS (
  VALUES
    ('Government of National Unity', 'government-of-national-unity', 'Executive', 'https://gnu.gov.ly', 1),
    ('Prime Minister Office', 'prime-minister-office', 'Executive', 'https://pm.gov.ly', 1),
    ('Ministry of Foreign Affairs and International Cooperation', 'ministry-foreign-affairs', 'Executive', 'https://foreign.gov.ly', 1),
    ('Ministry of Interior', 'ministry-interior', 'Security', 'https://moi.gov.ly', 1),
    ('Ministry of Defense', 'ministry-defense', 'Security', 'https://mod.gov.ly', 2),
    ('Ministry of Justice', 'ministry-justice', 'Judiciary', 'https://aladel.gov.ly', 1),
    ('Ministry of Finance', 'ministry-finance', 'Economy', 'https://mof.gov.ly', 1),
    ('Ministry of Economy and Trade', 'ministry-economy-trade', 'Economy', 'https://economy.gov.ly', 1),
    ('Ministry of Planning', 'ministry-planning', 'Economy', 'https://mop.gov.ly', 2),
    ('Ministry of Oil and Gas', 'ministry-oil-gas', 'Energy', 'https://oil.gov.ly', 1),
    ('Ministry of Health', 'ministry-health', 'Health', 'https://health.gov.ly', 1),
    ('Ministry of Education', 'ministry-education', 'Education', 'https://moe.gov.ly', 1),
    ('Ministry of Higher Education and Scientific Research', 'ministry-higher-education', 'Education', 'https://mhesr.gov.ly', 2),
    ('Ministry of Technical and Vocational Education', 'ministry-technical-vocational-education', 'Education', 'https://mtve.gov.ly', 3),
    ('Ministry of Transportation', 'ministry-transportation', 'Transport', 'https://mot.gov.ly', 2),
    ('Ministry of Housing and Construction', 'ministry-housing-construction', 'Infrastructure', 'https://mhc.gov.ly', 2),
    ('Ministry of Local Government', 'ministry-local-government', 'Local Government', 'https://mola.gov.ly', 2),
    ('Ministry of Labor and Rehabilitation', 'ministry-labor-rehabilitation', 'Executive', 'https://mol.gov.ly', 3),
    ('Ministry of Social Affairs', 'ministry-social-affairs', 'Executive', 'https://socialaffairs.gov.ly', 3),
    ('Ministry of Youth', 'ministry-youth', 'Executive', 'https://youth.gov.ly', 3),
    ('Ministry of Sport', 'ministry-sport', 'Executive', 'https://sports.gov.ly', 3),
    ('Ministry of Culture and Knowledge Development', 'ministry-culture', 'Culture', 'https://culture.gov.ly', 3),
    ('Ministry of Tourism and Traditional Industry', 'ministry-tourism', 'Culture', 'https://tourism.gov.ly', 3),
    ('Ministry of Water Resources', 'ministry-water-resources', 'Infrastructure', 'https://water.gov.ly', 3),
    ('Ministry of Environment', 'ministry-environment', 'Executive', 'https://environment.gov.ly', 3),
    ('House of Representatives', 'house-of-representatives', 'Legislature', 'https://parliament.ly', 1),
    ('High Council of State', 'high-council-of-state', 'Legislature', 'https://hcs.ly', 2),
    ('Presidential Council', 'presidential-council', 'Executive', 'https://pc.gov.ly', 1),
    ('Central Bank of Libya', 'central-bank-of-libya', 'Economy', 'https://cbl.gov.ly', 1),
    ('National Oil Corporation', 'national-oil-corporation', 'Energy', 'https://noc.ly', 1),
    ('Audit Bureau of Libya', 'audit-bureau-libya', 'Audit', 'https://audit.gov.ly', 1),
    ('Administrative Control Authority', 'administrative-control-authority', 'Regulator', 'https://aca.gov.ly', 2),
    ('High National Elections Commission', 'high-national-elections-commission', 'Elections', 'https://hnec.ly', 1),
    ('Libyan Investment Authority', 'libyan-investment-authority', 'Economy', 'https://lia.ly', 2),
    ('Libyan Post Telecommunications and Information Technology Holding Company', 'lptic', 'Infrastructure', 'https://lptic.ly', 3),
    ('General Electricity Company of Libya', 'general-electricity-company-libya', 'Infrastructure', 'https://gecol.ly', 1),
    ('National Center for Disease Control', 'national-center-disease-control', 'Health', 'https://ncdc.org.ly', 1),
    ('Libyan Customs Authority', 'libyan-customs-authority', 'Economy', 'https://customs.gov.ly', 2),
    ('Tax Authority', 'tax-authority', 'Economy', 'https://tax.gov.ly', 2),
    ('Libyan Ports Company', 'libyan-ports-company', 'Transport', 'https://libyanports.ly', 3),
    ('Civil Aviation Authority', 'civil-aviation-authority', 'Transport', 'https://caa.gov.ly', 3),
    ('Libyan Airports Authority', 'libyan-airports-authority', 'Transport', 'https://airports.gov.ly', 3),
    ('Roads and Bridges Authority', 'roads-bridges-authority', 'Infrastructure', 'https://rba.gov.ly', 3),
    ('National Safety Authority', 'national-safety-authority', 'Security', 'https://safety.gov.ly', 3),
    ('Civil Registry Authority', 'civil-registry-authority', 'Executive', 'https://cra.gov.ly', 2),
    ('Passports, Nationality and Foreigners Affairs Authority', 'passports-nationality-foreigners-affairs', 'Security', 'https://passport.gov.ly', 2),
    ('Municipality of Tripoli Center', 'municipality-tripoli-center', 'Local Government', 'https://tcm.gov.ly', 3),
    ('Municipality of Benghazi', 'municipality-benghazi', 'Local Government', 'https://benghazi.gov.ly', 3),
    ('Municipality of Misrata', 'municipality-misrata', 'Local Government', 'https://misurata.gov.ly', 3),
    ('Municipality of Sabha', 'municipality-sabha', 'Local Government', 'https://sabha.gov.ly', 3),
    ('Office of the Attorney General', 'office-attorney-general', 'Judiciary', 'https://ppo.gov.ly', 1),
    ('Supreme Judicial Council', 'supreme-judicial-council', 'Judiciary', 'https://sjc.gov.ly', 2)
), inserted_entities AS (
  INSERT INTO government_entities (name_en, slug, category_id, notes)
  SELECT es.name_en, es.slug, sc.id, 'Seeded Sprint 1 verified Libyan government entity'
  FROM entity_seed es
  JOIN source_categories sc ON sc.name = es.category_name
  ON CONFLICT (slug) DO UPDATE SET name_en = EXCLUDED.name_en, category_id = EXCLUDED.category_id
  RETURNING id, slug
), all_entities AS (
  SELECT id, slug FROM inserted_entities
  UNION
  SELECT id, slug FROM government_entities WHERE slug IN (SELECT slug FROM entity_seed)
), inserted_sources AS (
  INSERT INTO sources (entity_id, name, slug, language_code, priority, check_interval_minutes, enabled)
  SELECT ae.id, es.name_en, es.slug, 'en', es.priority, CASE WHEN es.priority = 1 THEN 60 ELSE 180 END, TRUE
  FROM entity_seed es
  JOIN all_entities ae ON ae.slug = es.slug
  ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, priority = EXCLUDED.priority, enabled = TRUE
  RETURNING id, slug
), all_sources AS (
  SELECT id, slug FROM inserted_sources
  UNION
  SELECT id, slug FROM sources WHERE slug IN (SELECT slug FROM entity_seed)
)
INSERT INTO source_urls (source_id, url_type, url, is_primary, enabled)
SELECT s.id, 'website'::source_url_type, es.website_url, TRUE, TRUE
FROM entity_seed es
JOIN all_sources s ON s.slug = es.slug
ON CONFLICT (source_id, url_type, url) DO UPDATE SET is_primary = TRUE, enabled = TRUE;

INSERT INTO app_settings (key, value, description) VALUES
  ('sprint', '1', 'Current implemented project sprint'),
  ('ai_enabled', 'false', 'AI analysis is intentionally disabled for Sprint 1'),
  ('facebook_enabled', 'false', 'Facebook collection is intentionally out of scope for Sprint 1'),
  ('x_enabled', 'false', 'X collection is intentionally out of scope for Sprint 1')
ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, description = EXCLUDED.description, updated_at = now();
