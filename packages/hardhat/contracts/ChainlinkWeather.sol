// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

library Weather {
    function getId(uint256 _locationKey) internal view returns (uint256) {
        if (_locationKey == 197700) {
            return (1);
        }
    }
}

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

/**
 * **** Data Conversions ****
 *
 * countryCode (bytes2)
 * --------------------
 * ISO 3166 alpha-2 codes encoded as bytes2
 * See: https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes
 *
 *
 * precipitationType (uint8)
 * --------------------------
 * Value    Type
 * --------------------------
 * 0        No precipitation
 * 1        Rain
 * 2        Snow
 * 3        Ice
 * 4        Mixed
 *
 *
 * weatherIcon (uint8)
 * -------------------
 * Each icon number is related with an image and a text
 * See: https://developer.accuweather.com/weather-icons
 *
 *
 * Decimals to integers (both metric & imperial units)
 * ---------------------------------------------------
 * Condition                    Conversion
 * ---------------------------------------------------
 * precipitationPast12Hours     multiplied by 100
 * precipitationPast24Hours     multiplied by 100
 * precipitationPastHour        multiplied by 100
 * pressure                     multiplied by 100
 * temperature                  multiplied by 10
 * windSpeed                    multiplied by 10
 *
 *
 * Current weather conditions units per system
 * ---------------------------------------------------
 * Condition                    metric      imperial
 * ---------------------------------------------------
 * precipitationPast12Hours     mm          in
 * precipitationPast24Hours     mm          in
 * precipitationPastHour        mm          in
 * pressure                     mb          inHg
 * temperature                  C           F
 * windSpeed                    km/h        mi/h
 *
 *
 * Other resources
 * ---------------
 * AccuWeather API docs:
 * http://apidev.accuweather.com/developers/
 *
 * Locations API Response Parameters:
 * http://apidev.accuweather.com/developers/locationAPIparameters#responseParameters
 *
 * Current Conditions API Response Parameters:
 * http://apidev.accuweather.com/developers/currentConditionsAPIParameters#responseParameters
 */
/**
 * @title A consumer contract for AccuWeather EA 'location-current-conditions' endpoint.
 * @author LinkPool.
 * @notice Request the current weather conditions for the given location coordinates (i.e. latitude and longitude).
 * @dev Uses @chainlink/contracts 0.4.0.
 */
contract AccuweatherConsumer is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    using Weather for uint256;
    bytes32 public reqId;

    /* ========== CONSUMER STATE VARIABLES ========== */

    struct RequestParams {
        uint256 locationKey;
        string endpoint;
        string lat;
        string lon;
        string units;
    }
    struct LocationResult {
        uint256 locationKey;
        string name;
        bytes2 countryCode;
    }
    struct CurrentConditionsResult {
        uint256 timestamp;
        uint24 precipitationPast12Hours;
        uint24 precipitationPast24Hours;
        uint24 precipitationPastHour;
        uint24 pressure;
        int16 temperature;
        uint16 windDirectionDegrees;
        uint16 windSpeed;
        uint8 precipitationType;
        uint8 relativeHumidity;
        uint8 uvIndex;
        uint8 weatherIcon;
    }

    // Maps
    mapping(bytes32 => CurrentConditionsResult)
        public requestIdCurrentConditionsResult;
    mapping(bytes32 => LocationResult) public requestIdLocationResult;
    mapping(bytes32 => RequestParams) public requestIdRequestParams;

    mapping(uint256 => uint8) internal IdtoWeather;
    mapping(bytes32 => uint8) internal ReqIdtoId;

    mapping(uint256 => uint8) public IdtoLatestWeather;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @param _link the LINK token address.
     * @param _oracle the Operator.sol contract address.
     */
    constructor(address _link, address _oracle) {
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);
    }

    /* ========== CONSUMER REQUEST FUNCTIONS ========== */

    /**
     * @notice Returns the location information for the given coordinates.
     * @param _payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
    //  */
    // function requestLocation(
    //     uint id,
    //     uint256 _payment
    // ) public {

    //     (string memory lat, string memory lon) = getter(id);
    //     Chainlink.Request memory req = buildChainlinkRequest("d67df9cb479e4b2e897f2769d1b0ff8e", address(this), this.fulfillLocation.selector);
    //     req.add("endpoint", "location"); // NB: not required if it has been hardcoded in the job spec
    //     req.add("lat", lat);
    //     req.add("lon", lon);

    //     bytes32 requestId = sendChainlinkRequest(req, _payment);

    //     // Below this line is just an example of usage
    //     storeRequestParams(requestId, 0, "location", lat, lon, "");
    // }

    /**
     * @notice Returns the current weather conditions of a location by ID.
     * @param _payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _locationKey the location ID.
     * @param _units the measurement system ("metric" or "imperial").
     */
    function requestCurrentConditions(
        uint256 _payment,
        uint256 _locationKey,
        string calldata _units
    ) public {
        Chainlink.Request memory req = buildChainlinkRequest(
            "0ef6e60880e24cb69cb99a1cad76f15a",
            address(this),
            this.fulfillCurrentConditions.selector
        );

        req.add("endpoint", "current-conditions"); // NB: not required if it has been hardcoded in the job spec
        req.addUint("locationKey", _locationKey);
        req.add("units", _units);

        reqId = sendChainlinkRequest(req, _payment);
        uint256 ids = _locationKey.getId();
        update(ids);

        // Below this line is just an example of usage
        storeRequestParams(
            reqId,
            _locationKey,
            "current-conditions",
            "0",
            "0",
            _units
        );
    }

    function weatherbyId(uint256 _id) external view returns (uint8) {
        return IdtoLatestWeather[_id];
    }

    function update(uint256 _id) internal {
        if (requestIdCurrentConditionsResult[reqId].precipitationType == 0) {
            IdtoLatestWeather[_id] = 0;
        } else if (
            requestIdCurrentConditionsResult[reqId].precipitationType == 1
        ) {
            IdtoLatestWeather[_id] = 1;
        } else if (
            requestIdCurrentConditionsResult[reqId].precipitationType == 2
        ) {
            IdtoLatestWeather[_id] = 2;
        } else if (
            requestIdCurrentConditionsResult[reqId].precipitationType == 3
        ) {
            IdtoLatestWeather[_id] = 3;
        } else if (
            requestIdCurrentConditionsResult[reqId].precipitationType == 4
        ) {
            IdtoLatestWeather[_id] = 4;
        }
    }

    /**
     * @notice Returns the current weather conditions of a location for the given coordinates.
     * @param _payment the LINK amount in Juels (i.e. 10^18 aka 1 LINK).
     * @param _lat the latitude (WGS84 standard, from -90 to 90).
     * @param _lon the longitude (WGS84 standard, from -180 to 180).
     * @param _units the measurement system ("metric" or "imperial").
     */

    function requestLocationCurrentConditions(
        uint256 _payment,
        string calldata _lat,
        string calldata _lon,
        string calldata _units
    ) public {
        Chainlink.Request memory req = buildChainlinkRequest(
            "7c276986e23b4b1c990d8659bca7a9d0",
            address(this),
            this.fulfillLocationCurrentConditions.selector
        );

        req.add("endpoint", "location-current-conditions"); // NB: not required if it has been hardcoded in the job spec
        req.add("lat", _lat);
        req.add("lon", _lon);
        req.add("units", _units);

        bytes32 requestId = sendChainlinkRequest(req, _payment);

        // Below this line is just an example of usage
        storeRequestParams(
            requestId,
            0,
            "location-current-conditions",
            _lat,
            _lon,
            _units
        );
    }

    /* ========== CONSUMER FULFILL FUNCTIONS ========== */

    /**
     * @notice Consumes the data returned by the node job on a particular request.
     * @dev Only when `_locationFound` is true, both `_locationFound` will contain meaningful data (as bytes). This
     * function body is just an example of usage.
     * @param _requestId the request ID for fulfillment.
     * @param _locationFound true if a location was found for the given coordinates, otherwise false.
     * @param _locationResult the location information (encoded as LocationResult).
     */
    function fulfillLocation(
        bytes32 _requestId,
        bool _locationFound,
        bytes memory _locationResult
    ) public recordChainlinkFulfillment(_requestId) {
        if (_locationFound) {
            storeLocationResult(_requestId, _locationResult);
        }
    }

    /**
     * @notice Consumes the data returned by the node job on a particular request.
     * @param _requestId the request ID for fulfillment.
     * @param _currentConditionsResult the current weather conditions (encoded as CurrentConditionsResult).
     */
    function fulfillCurrentConditions(
        bytes32 _requestId,
        bytes memory _currentConditionsResult
    ) public recordChainlinkFulfillment(_requestId) {
        storeCurrentConditionsResult(_requestId, _currentConditionsResult);
    }

    /**
     * @notice Consumes the data returned by the node job on a particular request.
     * @dev Only when `_locationFound` is true, both `_locationFound` and `_currentConditionsResult` will contain
     * meaningful data (as bytes). This function body is just an example of usage.
     * @param _requestId the request ID for fulfillment.
     * @param _locationFound true if a location was found for the given coordinates, otherwise false.
     * @param _locationResult the location information (encoded as LocationResult).
     * @param _currentConditionsResult the current weather conditions (encoded as CurrentConditionsResult).
     */
    function fulfillLocationCurrentConditions(
        bytes32 _requestId,
        bool _locationFound,
        bytes memory _locationResult,
        bytes memory _currentConditionsResult
    ) public recordChainlinkFulfillment(_requestId) {
        if (_locationFound) {
            storeLocationResult(_requestId, _locationResult);
            storeCurrentConditionsResult(_requestId, _currentConditionsResult);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function storeRequestParams(
        bytes32 _requestId,
        uint256 _locationKey,
        string memory _endpoint,
        string memory _lat,
        string memory _lon,
        string memory _units
    ) private {
        RequestParams memory requestParams;
        requestParams.locationKey = _locationKey;
        requestParams.endpoint = _endpoint;
        requestParams.lat = _lat;
        requestParams.lon = _lon;
        requestParams.units = _units;
        requestIdRequestParams[_requestId] = requestParams;
    }

    function storeLocationResult(
        bytes32 _requestId,
        bytes memory _locationResult
    ) private {
        LocationResult memory result = abi.decode(
            _locationResult,
            (LocationResult)
        );
        requestIdLocationResult[_requestId] = result;
    }

    function storeCurrentConditionsResult(
        bytes32 _requestId,
        bytes memory _currentConditionsResult
    ) private {
        CurrentConditionsResult memory result = abi.decode(
            _currentConditionsResult,
            (CurrentConditionsResult)
        );
        requestIdCurrentConditionsResult[_requestId] = result;
    }

    /* ========== OTHER FUNCTIONS ========== */

    function getOracleAddress() external view returns (address) {
        return chainlinkOracleAddress();
    }

    function setOracle(address _oracle) external {
        setChainlinkOracle(_oracle);
    }

    function withdrawLink() public {
        LinkTokenInterface linkToken = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        require(
            linkToken.transfer(msg.sender, linkToken.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
