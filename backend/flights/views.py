from rest_framework.decorators import api_view
from rest_framework.response import Response
from amadeus import Client, ResponseError, Location


# View pentru căutare zbor București-Madrid cu Amadeus API

def _get_amadeus_client():
	return Client(
		client_id='gtwTFdW8d9Pihy7yW6WLZDeZeqBdAlRd',
		client_secret='saWEFnHTG4M6aD6V'
	)


@api_view(['GET'])
def select_destination(request, param):
	try:
		amadeus = _get_amadeus_client()
		response = amadeus.reference_data.locations.get(
			keyword=param,
			subType=Location.ANY,
		)
		return Response({'data': response.data}, status=200)
	except ResponseError as error:
		details = None
		try:
			details = error.response.result
		except Exception:
			pass
		return Response({'error': str(error), 'details': details}, status=400)
	except Exception as e:
		return Response({'error': str(e)}, status=500)


@api_view(['GET'])
def search_flight(request):
	origin = request.GET.get('origin', 'OTP')
	destination = request.GET.get('destination', 'MAD')
	departure_date = request.GET.get('departureDate', '2026-03-10')
	trip_type = request.GET.get('trip_type', 'oneway')
	arrival_date = request.GET.get('arrivalDate')
	adults = request.GET.get('adults', '1')

	try:
		amadeus = _get_amadeus_client()
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
		airline_name_cache = {}
		checkin_link_cache = {}
		for offer in response.data:
			itineraries = offer.get('itineraries', [])
			if not itineraries:
				continue
			segments = itineraries[0].get('segments', [])
			if not segments:
				continue
			departure = segments[0]['departure']
			carrier_code = segments[0].get('carrierCode')
			offer_with_links = offer.copy()

			airline_name = airline_name_cache.get(carrier_code)
			if airline_name is None:
				try:
					airline_response = amadeus.reference_data.airlines.get(airlineCodes=carrier_code)
					airline_data = airline_response.data[0] if airline_response.data else {}
					airline_name = airline_data.get('businessName') or airline_data.get('commonName') or carrier_code
				except ResponseError:
					airline_name = carrier_code
				airline_name_cache[carrier_code] = airline_name

			checkin_link = checkin_link_cache.get(carrier_code)
			if checkin_link is None:
				try:
					checkin_response = amadeus.reference_data.urls.checkin_links.get(airlineCode=carrier_code)
					checkin_data = checkin_response.data[0] if checkin_response.data else {}
					checkin_link = checkin_data.get('href') or checkin_data.get('url')
				except ResponseError:
					checkin_link = None
				checkin_link_cache[carrier_code] = checkin_link

			offer_with_links['airline_name'] = airline_name
			if checkin_link:
				offer_with_links['checkin_link'] = checkin_link
			offers.append(offer_with_links)
		return Response({'offers': offers}, status=200)
	except ResponseError as error:
		details = None
		try:
			details = error.response.result
		except Exception:
			pass
		return Response({'error': str(error), 'details': details}, status=400)
	except Exception as e:
		return Response({'error': str(e)}, status=500)


@api_view(['POST'])
def price_offer(request):
	try:
		amadeus = _get_amadeus_client()
		payload = request.data
		response = amadeus.shopping.flight_offers.pricing.post(payload)
		return Response(response.data, status=200)
	except ResponseError as error:
		details = None
		try:
			details = error.response.result
		except Exception:
			pass
		return Response({'error': str(error), 'details': details}, status=400)
	except Exception as e:
		return Response({'error': str(e)}, status=500)


@api_view(['POST'])
def book_flight(request):
	try:
		amadeus = _get_amadeus_client()
		payload = request.data
		response = amadeus.booking.flight_orders.post(payload)
		return Response(response.data, status=200)
	except ResponseError as error:
		details = None
		try:
			details = error.response.result
		except Exception:
			pass
		return Response({'error': str(error), 'details': details}, status=400)
	except Exception as e:
		return Response({'error': str(e)}, status=500)
