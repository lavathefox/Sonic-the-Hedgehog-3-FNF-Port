package backend;

#if SWITCH_BUILD
@:keep
@:cppFileCode('
extern "C" {
	typedef unsigned int NxResult;
	extern char* fake_heap_start;
	extern char* fake_heap_end;
	bool envHasHeapOverride(void);
	void* envGetHeapOverrideAddr(void);
	unsigned long long envGetHeapOverrideSize(void);
	NxResult svcSetHeapSize(void** out_addr, unsigned long long size);

	#define SWITCH_FALLBACK_HEAP_BYTES 0x40000000ULL

	void __libnx_initheap(void)
	{
		void* addr = 0;
		unsigned long long size = 0;

		if (envHasHeapOverride())
		{
			addr = envGetHeapOverrideAddr();
			size = envGetHeapOverrideSize();
		}
		else
		{
			size = SWITCH_FALLBACK_HEAP_BYTES;
			if (svcSetHeapSize(&addr, size) != 0)
			{
				addr = 0;
				size = 0;
			}
		}

		fake_heap_start = (char*)addr;
		fake_heap_end = (char*)addr + size;
	}
}
')
#end
class SwitchHeap
{
	public static function init():Void {}
}
