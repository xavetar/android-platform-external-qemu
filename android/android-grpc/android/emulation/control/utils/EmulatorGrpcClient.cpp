// Copyright (C) 2020 The Android Open Source Project
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#include <grpcpp/grpcpp.h>  // for ClientC

#include <fstream>   // for ifstream
#include <iterator>  // for istre...
#include <map>       // for multimap
#include <memory>    // for shared_ptr
#include <memory>    // for alloc...
#include <string>    // for operator+
#include <string>    // for char_...
#include <utility>   // for __unwra...

#include "android/base/Stopwatch.h"
#include "android/base/StringView.h"                          // for StringView
#include "android/base/files/IniFile.h"                       // for IniFile
#include "android/base/files/PathUtils.h"                     // for IniFile
#include "android/emulation/control/secure/BasicTokenAuth.h"  // for BasicTo...
#include "android/emulation/control/utils/EmulatorGrcpClient.h"  // for Emulato...
#include "android/utils/debug.h"
#include "emulator_controller.grpc.pb.h"  // for Emulato...

namespace android {
namespace emulation {
namespace control {
using android::base::PathUtils;
using android::base::Stopwatch;

// A plugin that inserts the basic auth headers into a gRPC request
// if needed.
class BasicTokenAuthenticator : public grpc::MetadataCredentialsPlugin {
public:
    BasicTokenAuthenticator(const grpc::string& token)
        : mToken("Bearer " + token) {}
    ~BasicTokenAuthenticator() = default;

    grpc::Status GetMetadata(
            grpc::string_ref service_url,
            grpc::string_ref method_name,
            const grpc::AuthContext& channel_auth_context,
            std::multimap<grpc::string, grpc::string>* metadata) override {
        metadata->insert(std::make_pair(
                android::emulation::control::BasicTokenAuth::DEFAULT_HEADER,
                mToken));
        return grpc::Status::OK;
    }

private:
    grpc::string mToken;
};

bool EmulatorGrpcClient::hasOpenChannel(bool tryConnect) {
    if (!mChannel) {
        initializeChannel();
    }
    if (!mChannel)
        return false;

    if (tryConnect) {
        Stopwatch sw;
        auto waitUntil = gpr_time_add(gpr_now(GPR_CLOCK_REALTIME),
                                      gpr_time_from_seconds(5, GPR_TIMESPAN));
        bool connect = mChannel->WaitForConnected(waitUntil);
        double time = Stopwatch::sec(sw.elapsedUs());
        VERBOSE_PRINT(grpc, "%s to emulator: %s, after %f us",
                      connect ? "Connected" : "Not connected", mAddress.c_str(),
                      time);
    }
    auto state = mChannel->GetState(tryConnect);
    return state == GRPC_CHANNEL_READY || state == GRPC_CHANNEL_IDLE;
}

static std::string readFile(std::string fname) {
    std::ifstream fstream(PathUtils::asUnicodePath(fname).c_str());
    std::string contents((std::istreambuf_iterator<char>(fstream)),
                         std::istreambuf_iterator<char>());
    return contents;
}

EmulatorGrpcClient::EmulatorGrpcClient(std::string address,
                                       std::string ca,
                                       std::string key,
                                       std::string cer)
    : mAddress(address) {
    std::shared_ptr<grpc::ChannelCredentials> call_creds =
            ::grpc::InsecureChannelCredentials();
    if (!ca.empty() && !key.empty() && !cer.empty()) {
        // Client will use the server cert as the ca authority.
        grpc::SslCredentialsOptions sslOpts;
        sslOpts.pem_root_certs = readFile(ca);
        sslOpts.pem_private_key = readFile(key);
        sslOpts.pem_cert_chain = readFile(cer);
        call_creds = grpc::SslCredentials(sslOpts);
    }

    grpc::ChannelArguments maxSize;
    maxSize.SetMaxReceiveMessageSize(-1);
    mChannel = grpc::CreateCustomChannel(address, call_creds, maxSize);
}

std::unique_ptr<grpc::ClientContext> EmulatorGrpcClient::newContext() {
    auto ctx = std::make_unique<grpc::ClientContext>();
    if (mCredentials) {
        ctx->set_credentials(mCredentials);
    }
    return ctx;
}

bool EmulatorGrpcClient::initializeChannel() {
    android::base::IniFile iniFile(mDiscoveryFile);
    iniFile.read();
    if (!iniFile.hasKey("grpc.port") || iniFile.hasKey("grpc.server_cert")) {
        derror("No grpc port, or tls enabled. gRPC disabled.");
        return false;
    }
    mAddress = "localhost:" + iniFile.getString("grpc.port", "8554");

    grpc::ChannelArguments maxSize;
    maxSize.SetMaxReceiveMessageSize(-1);
    mChannel = grpc::CreateCustomChannel(
            mAddress, ::grpc::experimental::LocalCredentials(LOCAL_TCP),
            maxSize);

    // Install token authenticator if needed.
    if (iniFile.hasKey("grpc.token")) {
        auto token = iniFile.getString("grpc.token", "");
        mCredentials = grpc::MetadataCredentialsFromPlugin(
                std::make_unique<BasicTokenAuthenticator>(token));
    }
    return true;
}
}  // namespace control
}  // namespace emulation
}  // namespace android