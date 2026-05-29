// MAIN RUNTIME
using Windows.Devices.Radios;
//EXECUTION
class Program {
    static async Task Main(string[] args) {
        IReadOnlyList<Radio> radios = await Radio.GetRadiosAsync();
        foreach (Radio device in radios) {
            bool findBluetooth = device.Kind == RadioKind.Bluetooth;
            if (findBluetooth) {
                bool bluetoothIsOn = device.State == RadioState.On;
                if (bluetoothIsOn) {
                    try {
                        await device.SetStateAsync(RadioState.Off);
                        Console.WriteLine("Bluetooth successfully turned OFF");
                    }
                    catch (Exception ERROR) {
                        Console.WriteLine("Failed to turn off Bluetooth because " + ERROR.Message);
                    }
                }
                else {
                    Console.WriteLine("Bluetooth is already turned off.");
                }
            }
        }
    }
}