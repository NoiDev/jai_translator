crc_table : [256] u64;

crc_cursor : s32 = 0;  // This can go away once we no longer need init_crc64.
crc_value :: inline (v: u64) {
    crc_table[crc_cursor] = v;
    crc_cursor += 1;
}

init_crc64 :: () {
    // We do not have array literals yet so we need to initialize this dynamically.
    // This will be fixed! - jblow, 7 September 2015

    crc_value(0x0000000000000000); crc_value(0x42F0E1EBA9EA3693); 
    crc_value(0x85E1C3D753D46D26); crc_value(0xC711223CFA3E5BB5); 
    crc_value(0x493366450E42ECDF); crc_value(0x0BC387AEA7A8DA4C); 
    crc_value(0xCCD2A5925D9681F9); crc_value(0x8E224479F47CB76A); 
    crc_value(0x9266CC8A1C85D9BE); crc_value(0xD0962D61B56FEF2D); 
    crc_value(0x17870F5D4F51B498); crc_value(0x5577EEB6E6BB820B); 
    crc_value(0xDB55AACF12C73561); crc_value(0x99A54B24BB2D03F2); 
    crc_value(0x5EB4691841135847); crc_value(0x1C4488F3E8F96ED4); 
    crc_value(0x663D78FF90E185EF); crc_value(0x24CD9914390BB37C); 
    crc_value(0xE3DCBB28C335E8C9); crc_value(0xA12C5AC36ADFDE5A); 
    crc_value(0x2F0E1EBA9EA36930); crc_value(0x6DFEFF5137495FA3); 
    crc_value(0xAAEFDD6DCD770416); crc_value(0xE81F3C86649D3285); 
    crc_value(0xF45BB4758C645C51); crc_value(0xB6AB559E258E6AC2); 
    crc_value(0x71BA77A2DFB03177); crc_value(0x334A9649765A07E4); 
    crc_value(0xBD68D2308226B08E); crc_value(0xFF9833DB2BCC861D); 
    crc_value(0x388911E7D1F2DDA8); crc_value(0x7A79F00C7818EB3B); 
    crc_value(0xCC7AF1FF21C30BDE); crc_value(0x8E8A101488293D4D); 
    crc_value(0x499B3228721766F8); crc_value(0x0B6BD3C3DBFD506B); 
    crc_value(0x854997BA2F81E701); crc_value(0xC7B97651866BD192); 
    crc_value(0x00A8546D7C558A27); crc_value(0x4258B586D5BFBCB4); 
    crc_value(0x5E1C3D753D46D260); crc_value(0x1CECDC9E94ACE4F3); 
    crc_value(0xDBFDFEA26E92BF46); crc_value(0x990D1F49C77889D5); 
    crc_value(0x172F5B3033043EBF); crc_value(0x55DFBADB9AEE082C); 
    crc_value(0x92CE98E760D05399); crc_value(0xD03E790CC93A650A); 
    crc_value(0xAA478900B1228E31); crc_value(0xE8B768EB18C8B8A2); 
    crc_value(0x2FA64AD7E2F6E317); crc_value(0x6D56AB3C4B1CD584); 
    crc_value(0xE374EF45BF6062EE); crc_value(0xA1840EAE168A547D); 
    crc_value(0x66952C92ECB40FC8); crc_value(0x2465CD79455E395B); 
    crc_value(0x3821458AADA7578F); crc_value(0x7AD1A461044D611C); 
    crc_value(0xBDC0865DFE733AA9); crc_value(0xFF3067B657990C3A); 
    crc_value(0x711223CFA3E5BB50); crc_value(0x33E2C2240A0F8DC3); 
    crc_value(0xF4F3E018F031D676); crc_value(0xB60301F359DBE0E5); 
    crc_value(0xDA050215EA6C212F); crc_value(0x98F5E3FE438617BC); 
    crc_value(0x5FE4C1C2B9B84C09); crc_value(0x1D14202910527A9A); 
    crc_value(0x93366450E42ECDF0); crc_value(0xD1C685BB4DC4FB63); 
    crc_value(0x16D7A787B7FAA0D6); crc_value(0x5427466C1E109645); 
    crc_value(0x4863CE9FF6E9F891); crc_value(0x0A932F745F03CE02); 
    crc_value(0xCD820D48A53D95B7); crc_value(0x8F72ECA30CD7A324); 
    crc_value(0x0150A8DAF8AB144E); crc_value(0x43A04931514122DD); 
    crc_value(0x84B16B0DAB7F7968); crc_value(0xC6418AE602954FFB); 
    crc_value(0xBC387AEA7A8DA4C0); crc_value(0xFEC89B01D3679253); 
    crc_value(0x39D9B93D2959C9E6); crc_value(0x7B2958D680B3FF75); 
    crc_value(0xF50B1CAF74CF481F); crc_value(0xB7FBFD44DD257E8C); 
    crc_value(0x70EADF78271B2539); crc_value(0x321A3E938EF113AA); 
    crc_value(0x2E5EB66066087D7E); crc_value(0x6CAE578BCFE24BED); 
    crc_value(0xABBF75B735DC1058); crc_value(0xE94F945C9C3626CB); 
    crc_value(0x676DD025684A91A1); crc_value(0x259D31CEC1A0A732); 
    crc_value(0xE28C13F23B9EFC87); crc_value(0xA07CF2199274CA14); 
    crc_value(0x167FF3EACBAF2AF1); crc_value(0x548F120162451C62); 
    crc_value(0x939E303D987B47D7); crc_value(0xD16ED1D631917144); 
    crc_value(0x5F4C95AFC5EDC62E); crc_value(0x1DBC74446C07F0BD); 
    crc_value(0xDAAD56789639AB08); crc_value(0x985DB7933FD39D9B); 
    crc_value(0x84193F60D72AF34F); crc_value(0xC6E9DE8B7EC0C5DC); 
    crc_value(0x01F8FCB784FE9E69); crc_value(0x43081D5C2D14A8FA); 
    crc_value(0xCD2A5925D9681F90); crc_value(0x8FDAB8CE70822903); 
    crc_value(0x48CB9AF28ABC72B6); crc_value(0x0A3B7B1923564425); 
    crc_value(0x70428B155B4EAF1E); crc_value(0x32B26AFEF2A4998D); 
    crc_value(0xF5A348C2089AC238); crc_value(0xB753A929A170F4AB); 
    crc_value(0x3971ED50550C43C1); crc_value(0x7B810CBBFCE67552); 
    crc_value(0xBC902E8706D82EE7); crc_value(0xFE60CF6CAF321874); 
    crc_value(0xE224479F47CB76A0); crc_value(0xA0D4A674EE214033); 
    crc_value(0x67C58448141F1B86); crc_value(0x253565A3BDF52D15); 
    crc_value(0xAB1721DA49899A7F); crc_value(0xE9E7C031E063ACEC); 
    crc_value(0x2EF6E20D1A5DF759); crc_value(0x6C0603E6B3B7C1CA); 
    crc_value(0xF6FAE5C07D3274CD); crc_value(0xB40A042BD4D8425E); 
    crc_value(0x731B26172EE619EB); crc_value(0x31EBC7FC870C2F78); 
    crc_value(0xBFC9838573709812); crc_value(0xFD39626EDA9AAE81); 
    crc_value(0x3A28405220A4F534); crc_value(0x78D8A1B9894EC3A7); 
    crc_value(0x649C294A61B7AD73); crc_value(0x266CC8A1C85D9BE0); 
    crc_value(0xE17DEA9D3263C055); crc_value(0xA38D0B769B89F6C6); 
    crc_value(0x2DAF4F0F6FF541AC); crc_value(0x6F5FAEE4C61F773F); 
    crc_value(0xA84E8CD83C212C8A); crc_value(0xEABE6D3395CB1A19); 
    crc_value(0x90C79D3FEDD3F122); crc_value(0xD2377CD44439C7B1); 
    crc_value(0x15265EE8BE079C04); crc_value(0x57D6BF0317EDAA97); 
    crc_value(0xD9F4FB7AE3911DFD); crc_value(0x9B041A914A7B2B6E); 
    crc_value(0x5C1538ADB04570DB); crc_value(0x1EE5D94619AF4648); 
    crc_value(0x02A151B5F156289C); crc_value(0x4051B05E58BC1E0F); 
    crc_value(0x87409262A28245BA); crc_value(0xC5B073890B687329); 
    crc_value(0x4B9237F0FF14C443); crc_value(0x0962D61B56FEF2D0); 
    crc_value(0xCE73F427ACC0A965); crc_value(0x8C8315CC052A9FF6); 
    crc_value(0x3A80143F5CF17F13); crc_value(0x7870F5D4F51B4980); 
    crc_value(0xBF61D7E80F251235); crc_value(0xFD913603A6CF24A6); 
    crc_value(0x73B3727A52B393CC); crc_value(0x31439391FB59A55F); 
    crc_value(0xF652B1AD0167FEEA); crc_value(0xB4A25046A88DC879); 
    crc_value(0xA8E6D8B54074A6AD); crc_value(0xEA16395EE99E903E); 
    crc_value(0x2D071B6213A0CB8B); crc_value(0x6FF7FA89BA4AFD18); 
    crc_value(0xE1D5BEF04E364A72); crc_value(0xA3255F1BE7DC7CE1); 
    crc_value(0x64347D271DE22754); crc_value(0x26C49CCCB40811C7); 
    crc_value(0x5CBD6CC0CC10FAFC); crc_value(0x1E4D8D2B65FACC6F); 
    crc_value(0xD95CAF179FC497DA); crc_value(0x9BAC4EFC362EA149); 
    crc_value(0x158E0A85C2521623); crc_value(0x577EEB6E6BB820B0); 
    crc_value(0x906FC95291867B05); crc_value(0xD29F28B9386C4D96); 
    crc_value(0xCEDBA04AD0952342); crc_value(0x8C2B41A1797F15D1); 
    crc_value(0x4B3A639D83414E64); crc_value(0x09CA82762AAB78F7); 
    crc_value(0x87E8C60FDED7CF9D); crc_value(0xC51827E4773DF90E); 
    crc_value(0x020905D88D03A2BB); crc_value(0x40F9E43324E99428); 
    crc_value(0x2CFFE7D5975E55E2); crc_value(0x6E0F063E3EB46371); 
    crc_value(0xA91E2402C48A38C4); crc_value(0xEBEEC5E96D600E57); 
    crc_value(0x65CC8190991CB93D); crc_value(0x273C607B30F68FAE); 
    crc_value(0xE02D4247CAC8D41B); crc_value(0xA2DDA3AC6322E288); 
    crc_value(0xBE992B5F8BDB8C5C); crc_value(0xFC69CAB42231BACF); 
    crc_value(0x3B78E888D80FE17A); crc_value(0x7988096371E5D7E9); 
    crc_value(0xF7AA4D1A85996083); crc_value(0xB55AACF12C735610); 
    crc_value(0x724B8ECDD64D0DA5); crc_value(0x30BB6F267FA73B36); 
    crc_value(0x4AC29F2A07BFD00D); crc_value(0x08327EC1AE55E69E); 
    crc_value(0xCF235CFD546BBD2B); crc_value(0x8DD3BD16FD818BB8); 
    crc_value(0x03F1F96F09FD3CD2); crc_value(0x41011884A0170A41); 
    crc_value(0x86103AB85A2951F4); crc_value(0xC4E0DB53F3C36767); 
    crc_value(0xD8A453A01B3A09B3); crc_value(0x9A54B24BB2D03F20); 
    crc_value(0x5D45907748EE6495); crc_value(0x1FB5719CE1045206); 
    crc_value(0x919735E51578E56C); crc_value(0xD367D40EBC92D3FF); 
    crc_value(0x1476F63246AC884A); crc_value(0x568617D9EF46BED9); 
    crc_value(0xE085162AB69D5E3C); crc_value(0xA275F7C11F7768AF); 
    crc_value(0x6564D5FDE549331A); crc_value(0x279434164CA30589); 
    crc_value(0xA9B6706FB8DFB2E3); crc_value(0xEB46918411358470); 
    crc_value(0x2C57B3B8EB0BDFC5); crc_value(0x6EA7525342E1E956); 
    crc_value(0x72E3DAA0AA188782); crc_value(0x30133B4B03F2B111); 
    crc_value(0xF7021977F9CCEAA4); crc_value(0xB5F2F89C5026DC37); 
    crc_value(0x3BD0BCE5A45A6B5D); crc_value(0x79205D0E0DB05DCE); 
    crc_value(0xBE317F32F78E067B); crc_value(0xFCC19ED95E6430E8); 
    crc_value(0x86B86ED5267CDBD3); crc_value(0xC4488F3E8F96ED40); 
    crc_value(0x0359AD0275A8B6F5); crc_value(0x41A94CE9DC428066); 
    crc_value(0xCF8B0890283E370C); crc_value(0x8D7BE97B81D4019F); 
    crc_value(0x4A6ACB477BEA5A2A); crc_value(0x089A2AACD2006CB9); 
    crc_value(0x14DEA25F3AF9026D); crc_value(0x562E43B4931334FE); 
    crc_value(0x913F6188692D6F4B); crc_value(0xD3CF8063C0C759D8); 
    crc_value(0x5DEDC41A34BBEEB2); crc_value(0x1F1D25F19D51D821); 
    crc_value(0xD80C07CD676F8394); crc_value(0x9AFCE626CE85B507);
}; 

depend :: #run init_crc64();

crc64 :: (s: string) -> u64 {
    depend;  // Make sure that if we run this at compile time the table initializer has already run; we should have a better way of notating this.
    
    sum : u64 = 0xFFFFFFFFFFFFFFFF;

    for 0..s.count-1 {
        byte := s[it];
        
        tab_index := ((sum >> 56) ^ byte) & 0xFF;
        
        sum = crc_table[tab_index] ^ (sum << 8);
    } 

    sum = sum ^ 0xFFFFFFFFFFFFFFFF;
    return sum;
}

