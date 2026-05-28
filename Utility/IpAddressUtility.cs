using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Web;

namespace ACS.Core.Utility
{
    public class IpAddressUtility
    {
        /// <summary>
        /// Check to see if an incoming IP Address matches exactly or a wildcard range as denoted by asterisks.
        /// </summary>
        /// <param name="ipAddress">An Ip Address to search for.</param>
        /// <param name="ipAddressList">The list of Ip Addresses to search for a given ipAddress.</param>
        /// <param name="wildcardOctetsToSearch">The number of wildcard octets to search against, starting from the highest octet and searching backwards.</param>
        /// <returns>True if the ipAddress is either an exact match to one in ipAddressList or matches an item in ipAddressList based on an Ip Address range.</returns>
        public static bool IsMatch(string ipAddress, IEnumerable<string> ipAddressList, int wildcardOctetsToSearch)
        {
            if (wildcardOctetsToSearch < 1 || wildcardOctetsToSearch > 4)
                throw new ArgumentOutOfRangeException(nameof(wildcardOctetsToSearch));

            ipAddressList = ipAddressList.ToList();

            var ip = ipAddress.Split('.');
            var oneOctetMask = $"{ip[0]}.{ip[1]}.{ip[2]}.*";
            var twoOctetMask = $"{ip[0]}.{ip[1]}.*.*";
            var threeOctetMask = $"{ip[0]}.*.*.*";

            if (ipAddressList.Contains(ipAddress))
                return true;

            // do a reverse search from the last octet 
            switch (wildcardOctetsToSearch)
            {
                case 1:
                {
                    if (ipAddressList.Contains(oneOctetMask))
                        return true;

                    break;
                }
                case 2:
                {
                    if (ipAddressList.Contains(oneOctetMask) ||
                        ipAddressList.Contains(twoOctetMask))
                        return true;

                    break;
                }
                case 3:
                {
                    if (ipAddressList.Contains(oneOctetMask) ||
                        ipAddressList.Contains(twoOctetMask) ||
                        ipAddressList.Contains(threeOctetMask))
                        return true;

                    break;
                }
                case 4:
                {
                    // if we get to this point for some reason we have a blanket 
                    // ip address being searched (*.*.*.*) so technically it's been found
                    return true;
                }
            }

            return false;
        }

        public static string GetIpAddress(HttpRequest request)
        {
            return request.ServerVariables["HTTP_X_FORWARDED_FOR"] ?? request.ServerVariables["REMOTE_ADDR"];
		}
    }
}
