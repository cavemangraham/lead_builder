require 'rake'
namespace :grabber do
	task :businesses, [:region, :locality] => [:environment] do |t, args|
		args.with_defaults(:region => "NJ", :locality => "newark")
		require 'factual'
		factual = Factual.new("WevzSzGmAiUz27P0yi5Wak1c2EGWeaVT076pTiEp","hnd5j1bxG8VYMDlqZs3dSBvkIc8U47FbB56fVp1p")

		directory_size = factual.facets("places-us").select("locality").filters("$and" => [{"region" => {"$eq" => args[:region]}}, {"locality" => {"$eq" => args[:locality]}}]).columns
		directory_size["locality"][args[:locality]]
		p "#{directory_size}"

		(0..10).each do |current_page|

			directory = factual.table("places-us").search("").filters("$and" => [{"locality" => {"$eq" =>  args[:locality]}}, {"region" => {"$eq" => args[:region]}}]).page(current_page, :per => 50).rows
			(0..49).each do |x|
				business = Business.create(:name => directory[x]["name"],
										   :address => directory[x]["address"],
										   :email => directory[x]["email"],
										   :phone => directory[x]["tel"], 
										   :website => directory[x]["website"])
				p "Grabbed - #{business.name}"
			end
		end
	end
	task responsive: [:environment] do
		Business.all.each do |business|
				if business.website.present? and business.responsive.blank?
					begin
					response = HTTParty.get('http://tools.mercenie.com/responsive-check/api/?format=json&url=' + business.website, timeout: 1)
					rescue Net::ReadTimeout, Net::OpenTimeout
						response = "error"
					end
					p "#{business.name} - #{business.responsive}"
					p "#{response}"
					if response != "error" and response.exclude? "Warning"
						business.responsive = response["responsive"]
						business.save
						p "#{business.name} - #{business.responsive}"
					else
						business.responsive = "error"
						business.save
					end
				else
					business.responsive = "error"
					business.save
				end
		end
	end
end