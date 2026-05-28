using JWT.Builder;
using JWT.Algorithms;

namespace ACS.Core.Security
{
	public interface ITokenGenerator
	{
		string GetToken
		(
			string secret,
			string audience,
			string issuer,
			long timeToExpire,
			string userId,
			string chartIdentifier,
			string facilityId,
			bool evaluateFacilityService,
			bool evaluatePhysicianService,
			string ssoUserObjectIdentifier
		);

		string GetToken(
			string secret,
			string audience,
			string issuer,
			long timeToExpire,
			string ssoOid,
			string ssoRole
		);

	}

	public class JwtTokenGenerator : ITokenGenerator
    {
	    public string GetToken
        (
	        string secret,
	        string audience,
	        string issuer,
	        long timeToExpire,
	        string userId, 
	        string chartIdentifier, 
	        string facilityId,
			bool evaluateFacilityService,
			bool evaluatePhysicianService,
			string ssoUserObjectIdentifier
		) =>
	        JwtBuilder.Create()
		        .WithAlgorithm(new HMACSHA256Algorithm()) // symmetric
		        .WithSecret(secret)
		        .Audience(audience)
		        .Issuer(issuer)
		        .AddClaim("exp", timeToExpire)
		        .AddClaim("userId", userId)
		        .AddClaim("chartId", chartIdentifier)
		        .AddClaim("facilityId", facilityId)
		        .AddClaim(nameof(evaluateFacilityService), evaluateFacilityService)
		        .AddClaim(nameof(evaluatePhysicianService), evaluatePhysicianService)
		        .AddClaim("oid", ssoUserObjectIdentifier)
		        .Encode();


		public string GetToken(
			string secret, 
			string audience, 
			string issuer, 
			long timeToExpire, 
			string ssoOid,
			string ssoRole
		) =>
			JwtBuilder.Create()
				.WithAlgorithm(new HMACSHA256Algorithm()) // symmetric
				.WithSecret(secret)
				.Audience(audience)
				.Issuer(issuer)
				.AddClaim("exp", timeToExpire)
				.AddClaim("oid", ssoOid)
				.AddClaim("role", ssoRole)
				.Encode();
	}
}
