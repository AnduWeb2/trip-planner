from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .serializer import UserRegisterSerializer, LogoutSerializer
from amadeus import Client, ResponseError
from urllib.parse import quote, urlencode
import json
# Create your views here.

@api_view(['POST'])
def register(request):
    data = request.data
    serializer = UserRegisterSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response({"message": "User registered successfully"}, status=201)
    return Response(serializer.errors, status=400)

@api_view(['POST'])
def logout(request):
    data  = request.data
    serializer = LogoutSerializer(data=data)
    if serializer.is_valid():
        serializer.save()
        return Response({"message": "User logged out successfully"}, status=200)
    return Response(serializer.errors, status=400)


# Dicționar cod companie -> site oficial
AIRLINE_URLS = {
    'LH': 'https://www.lufthansa.com',
    'RO': 'https://www.tarom.ro',
    'AF': 'https://www.airfrance.com',
    'KL': 'https://www.klm.com',
    'BA': 'https://www.britishairways.com',
    'W6': 'https://wizzair.com',
    'FR': 'https://www.ryanair.com',
    'AZ': 'https://www.ita-airways.com',
    'TK': 'https://www.turkishairlines.com',
    'OS': 'https://www.austrian.com',
    'LO': 'https://www.lot.com',
    'SU': 'https://www.aeroflot.ru',
    'QR': 'https://www.qatarairways.com',
    'EK': 'https://www.emirates.com',
    'UA': 'https://www.united.com',
    'AA': 'https://www.aa.com',
    'DL': 'https://www.delta.com',
    'LX': 'https://www.swiss.com',
    'IB': 'https://www.iberia.com',
    'VY': 'https://www.vueling.com',
    
}

def generate_tarom_booking_link(origin, destination, date):
    # Format: https://digital.tarom.ro/booking?lang=ro-RO&search={...}&portalFacts=[...]
    search_dict = {
        "travelers": [{"passengerTypeCode": "ADT"}],
        "commercialFareFamilies": ["EUROPE"],
        "itineraries": [{
            "departureDateTime": date,
            "originLocationCode": origin,
            "destinationLocationCode": destination
        }]
    }
    portal_facts = [
        {"key": "currency", "value": "EUR"},
        {"key": "channel", "value": "desktop"}
    ]
    params = {
        "lang": "ro-RO",
        "search": json.dumps(search_dict, separators=(',', ':')),
        "portalFacts": json.dumps(portal_facts, separators=(',', ':'))
    }
    # urlencode, dar search și portalFacts trebuie să fie quoted
    params["search"] = quote(params["search"])
    params["portalFacts"] = quote(params["portalFacts"])
    return f"https://digital.tarom.ro/booking?{urlencode(params)}"

# Generează link British Airways (oneway sau round)
def generate_ba_booking_link(origin, destination, departure_date, trip_type="oneway", arrival_date=None):
    base_url = "https://www.britishairways.com/nx/b/airselect/en/rou/book/search/"
    params = {
        "trip": trip_type,
        "from": origin,
        "to": destination,
        "departureDate": departure_date,
        "travelClass": "economy",
        "adults": 1,
        "youngAdults": 0,
        "children": 0,
        "infants": 0,
        "bound": "outbound"
    }
    if trip_type == "round" and arrival_date:
        params["arrivalDate"] = arrival_date
    return f"{base_url}?{urlencode(params)}"

# View pentru căutare zbor București-Madrid cu Amadeus API

@api_view(['GET'])
def search_flight(request):
    origin = request.GET.get('origin', 'OTP')
    destination = request.GET.get('destination', 'MAD')
    departure_date = request.GET.get('departureDate', '2026-03-10')
    trip_type = request.GET.get('trip_type', 'oneway')
    arrival_date = request.GET.get('arrivalDate')
    adults = request.GET.get('adults', '1')

    try:
        amadeus = Client(
            client_id='gtwTFdW8d9Pihy7yW6WLZDeZeqBdAlRd',
            client_secret='saWEFnHTG4M6aD6V'
        )
        amadeus_params = {
            'originLocationCode': origin,
            'destinationLocationCode': destination,
            'departureDate': departure_date,
            'adults': int(adults),
            'nonStop': 'false',
            'max': 3
        }
        if trip_type == 'round' and arrival_date:
            amadeus_params['returnDate'] = arrival_date
        response = amadeus.shopping.flight_offers_search.get(**amadeus_params)
        offers = []
        for offer in response.data:
            itineraries = offer.get('itineraries', [])
            if not itineraries:
                continue
            segments = itineraries[0].get('segments', [])
            if not segments:
                continue
            departure = segments[0]['departure']
            seg_origin = departure['iataCode']
            seg_date = departure['at'][:10]
            seg_destination = segments[-1]['arrival']['iataCode']
            carrier_code = segments[0].get('carrierCode')
            airline_url = AIRLINE_URLS.get(carrier_code)
            google_link = f"https://www.google.com/flights?hl=en#flt={seg_origin}.{seg_destination}.{seg_date};c:EUR;e:1;sd:1;t:f"
            skyscanner_link = f"https://www.skyscanner.net/transport/flights/{seg_origin.lower()}/{seg_destination.lower()}/{seg_date.replace('-', '')}/?adults=1"
            expedia_link = f"https://www.expedia.com/Flights-Search?trip=oneway&leg1=from:{seg_origin},to:{seg_destination},departure:{seg_date}TANYT&passengers=adults:1&options=cabinclass:economy&mode=search"
            offer_with_links = offer.copy()
            offer_with_links['google_flights_link'] = google_link
            offer_with_links['skyscanner_link'] = skyscanner_link
            offer_with_links['expedia_link'] = expedia_link
            if airline_url:
                offer_with_links['airline_booking_link'] = airline_url
            if carrier_code == 'RO':
                offer_with_links['tarom_direct_booking_link'] = generate_tarom_booking_link(seg_origin, seg_destination, seg_date)
            if carrier_code == 'BA':
                ba_link = generate_ba_booking_link(seg_origin, seg_destination, seg_date, trip_type=trip_type, arrival_date=arrival_date)
                offer_with_links['british_airways_direct_booking_link'] = ba_link
            offers.append(offer_with_links)
        return Response(offers, status=200)
    except ResponseError as error:
        details = None
        try:
            details = error.response.result
        except Exception:
            pass
        return Response({'error': str(error), 'details': details}, status=400)
    except Exception as e:
        return Response({'error': str(e)}, status=500)
