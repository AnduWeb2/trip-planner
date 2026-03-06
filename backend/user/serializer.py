import pycountry
from rest_framework import serializers
from .models import User, TravelerProfile
from django.contrib.auth.password_validation import validate_password
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.exceptions import TokenError
from rest_framework.exceptions import ValidationError

VALID_NATIONALITY = {
    country.alpha_2 for country in pycountry.countries
}
VALID_PHONE_CODE = {
    country.numeric for country in pycountry.countries
}


class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('username', 'email', 'password', 'password2')

    def validate(self, validated_data):
        if validated_data['password'] != validated_data['password2']:
            raise serializers.ValidationError({"password": "Passwords don't match."})
        return validated_data

    def create(self, validated_data):
        user = User.objects.create(
            username=validated_data['username'],
            email=validated_data['email'],
        )
        user.set_password(validated_data['password'])
        user.save()
        return user
    
class LogoutSerializer(serializers.Serializer):
    refresh = serializers.CharField()

    def validate(self, attrs):
        self.token = attrs['refresh']
        try:
            RefreshToken(self.token)
        except TokenError:
            raise ValidationError("Invalid token")

        
        return attrs
    
    def save(self, **kwargs):
        RefreshToken(self.token).blacklist()
    
class TravelerProfileSerializer(serializers.ModelSerializer):
    
    class Meta:
        model = TravelerProfile
        fields = ('id','first_name', 'last_name','date_of_birth','gender','phone_country_code','phone_number','nationality')

    def validate_phone_country_code(self, value):
        if value not in VALID_PHONE_CODE:
            raise serializers.ValidationError("Invalid phone prefix")
        return value
    
    def validate_nationality(self, attrs):
        if attrs not in VALID_NATIONALITY:
            raise serializers.ValidationError("Invalid Nationality")
        return attrs
    
    def create(self, validated_data):
        traveler  = TravelerProfile.objects.create(**validated_data)

        return traveler