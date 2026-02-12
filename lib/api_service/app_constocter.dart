class App_Constructor {
  final BaseURL = "https://qadampayk.com";
  final istestmode = true;


  //auth
final login = "/api/login";
final verify_otp = "/api/verify-otp";
final logout = "/api/logout";
final get_profile = "/api/get-profile";


  // search
  final getCity = "/api/get-city";
  final getCarBrand = "/api/get-car-brands";
  final getCarModel = "/api/get-car-models/volkswagen beetle";

  // ass vehical
  final addCar = "/api/driver/add-vehicle";
  final fetchCar = "/api/driver/get-vehicles";
  final fetchServices = "/api/get-services?language=ru";
  final updateCar = "/api/driver/edit-vehicle";

 // ride
  final publishRide = "/api/driver/create-ride";
  final passenger_request = "/api/store-ride-request";
  final fetchtripridelist = "/api/search-rides";
  final fetchriderequestlist = "/api/all-ride-requests";
  final fetchParcelequestlist = "/api/all-parcel-requests";
  final updateRide = "/api/driver/edit-ride"; // 🔁 backend endpoint


  // driver
  final fetchdriverdetail= "/api/driver-details";
  final driverintrestrequest= "/api/driver/interest-request";


}