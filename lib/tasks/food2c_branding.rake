namespace :food2c do
  desc 'Apply the Food2C identity to an existing Chatwoot installation'
  task apply_branding: :environment do
    names = %w[
      INSTALLATION_NAME BRAND_NAME BRAND_URL WIDGET_BRAND_URL
      LOGO LOGO_DARK LOGO_THUMBNAIL DISPLAY_MANIFEST
    ]
    values = ConfigLoader.new.general_configs.index_by { |config| config.fetch('name') }

    names.each do |name|
      config = InstallationConfig.find_or_initialize_by(name: name)
      value = values.fetch(name).fetch('value')
      config.update!(value: value) if config.new_record? || config.value != value
    end

    puts 'Food2C branding applied to installation settings'
  end
end
