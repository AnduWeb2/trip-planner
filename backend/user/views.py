from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from .serializer import UserRegisterSerializer, LogoutSerializer, TravelerProfileSerializer
# Create your views here.

@api_view(['POST'])
@permission_classes([AllowAny])
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


@api_view(['POST'])
def create_traveler(request):
    data = request.data
    user = request.user
    serializer = TravelerProfileSerializer(data=data)

    if serializer.is_valid():
        serializer.save(user=user)
        return Response({"message": "Traveler created succesfully"}, status=201)
    return Response(serializer.errors, status=400)
