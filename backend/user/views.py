from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .serializer import UserRegisterSerializer, LogoutSerializer
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


