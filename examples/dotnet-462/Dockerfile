FROM mcr.microsoft.com/dotnet/framework/sdk:4.8 as build
WORKDIR /app

# copy csproj and restore as distinct layers
COPY *.sln .
COPY app/*.csproj ./app/
COPY app/*.config ./app/
RUN nuget sources list
RUN nuget restore

# copy everything else and build app
COPY app/. ./app/
WORKDIR /app/app
RUN msbuild /p:Configuration=Release -r:False


FROM mcr.microsoft.com/dotnet/framework/aspnet:4.6.2 AS runtime
WORKDIR /inetpub/wwwroot
COPY --from=build /app/app/. ./