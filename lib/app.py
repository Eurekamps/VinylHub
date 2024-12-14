from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

vinyl_prices = {
    "Dark Side of the Moon": 19.99,
    "Abbey Road": 22.50
}

external_apis = [
    {
        "name": "Discogs",
        "url": "https://api.discogs.com/database/search?q={}&type=release&token=YOUR_DISCogs_API_KEY"
    },
    {
        "name": "eBay",
        "url": "https://api.ebay.com/buy/browse/v1/item_summary/search?q={}&limit=5&api_key=YOUR_EBAY_API_KEY"
    }
]

@app.route('/compare-prices', methods=['GET'])
def compare_prices():
    vinyl_name = request.args.get('vinylName')
    if not vinyl_name:
        return jsonify({"error": "Vinyl name is required"}), 400

    app_price = vinyl_prices.get(vinyl_name, "Not Available")
    store_prices = []

    for api in external_apis:
        try:
            response = requests.get(api["url"].format(vinyl_name), timeout=5)
            response.raise_for_status()
            data = response.json()
            # Ajusta esto según la estructura de la API
            store_prices.append({
                "store": api["name"],
                "price": data.get('price', 'Unknown'),
                "url": data.get('url', '#')
            })
        except requests.exceptions.RequestException as e:
            store_prices.append({
                "store": api["name"],
                "price": "Error fetching data",
                "url": "#",
                "error": str(e)
            })

    return jsonify({
        "vinyl": vinyl_name,
        "app_price": app_price,
        "stores": store_prices
    })

if __name__ == '__main__':
    app.run(debug=True)

