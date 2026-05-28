using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using AutoFixture;

namespace ACS.Core.Extensions
{
    public static class AutoFixtureExtensions
    {
        public static int CreateRangedInt(this IFixture fixture, int min, int max)
        {
            return fixture.Create<int>() % (max - min + 1) + min;
        }

        public static string CreateIpAddress(this IFixture fixture, int wildcardCount = 0)
        {
            var octet1 = wildcardCount == 4 ? "*" : CreateRangedInt(fixture, 1, 999).ToString();
            var octet2 = wildcardCount == 3 ? "*" : CreateRangedInt(fixture, 1, 999).ToString();
            var octet3 = wildcardCount == 2 ? "*" : CreateRangedInt(fixture, 1, 999).ToString();
            var octet4 = wildcardCount == 1 ? "*" : CreateRangedInt(fixture, 1, 999).ToString();

            return $"{octet1}.{octet2}.{octet3}.{octet4}";
        }

        public static List<string> CreateManyIpAddresses(this IFixture fixture, int count = 3)
        {
            var ipAddressList = new List<string>();

            for(var i = 0; i < count; i++)
                ipAddressList.Add(CreateIpAddress(fixture));

            return ipAddressList;
        }
    }
}
