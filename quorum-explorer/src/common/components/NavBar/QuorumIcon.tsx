
import { useColorModeValue, useColorMode, Icon } from "@chakra-ui/react";

export const QuorumIcon = ({ ...rest }) => {
  const { colorMode } = useColorMode();
  const lightMode = "gray.800";
  const darkMode = "white";
  const colorFill = useColorModeValue(lightMode, darkMode);

  return (
    <>
      <Icon height="50px" width="50px" viewBox="0 0 165 163">
        <svg width="165" height="163" xmlns="http://www.w3.org/2000/svg">
          <path
            fill={colorFill}
            d="M82.5 0C36.934 0 0 36.399 0 81.304c0 44.906 36.934 81.305 82.5 81.305S165 126.21 165 81.304C165 36.4 128.066 0 82.5 0z"
          ></path>
          <path
            fill={colorMode === "light" ? "white" : "gray.800"}
            d="M129.683 92.152a6.572 6.572 0 0 0-6.529 6.605v.011a6.561 6.561 0 0 0 6.529 6.593 6.572 6.572 0 0 0 6.529-6.593 6.566 6.566 0 0 0-6.511-6.616h-.018zM126.937 80.803c3.163-1.826 4.254-5.875 2.428-9.037-1.827-3.163-5.876-4.254-9.038-2.428a6.619 6.619 0 0 0-2.451 8.997l.041.059a6.594 6.594 0 0 0 9.014 2.41c0 .005 0 .005.006 0zM45.608 69.38a6.616 6.616 0 0 0-9.043 2.403 6.616 6.616 0 0 0 2.403 9.044 6.616 6.616 0 0 0 9.044-2.404V78.4a6.605 6.605 0 0 0-2.404-9.02zM59.127 64.87a6.619 6.619 0 0 0 5.741-9.885 6.596 6.596 0 0 0-8.99-2.491c-.007 0-.007.006-.012.006l-.111.064a6.617 6.617 0 0 0 3.372 12.305zM82.763 45.218a6.619 6.619 0 0 0-6.616 6.616 6.618 6.618 0 0 0 6.616 6.617 6.619 6.619 0 0 0 6.617-6.617 6.619 6.619 0 0 0-6.617-6.616zM103.027 63.935l.082.047a6.616 6.616 0 0 0 6.599-11.447 6.617 6.617 0 0 0-6.681 11.4zM36.003 92.151c-3.641-.058-6.652 2.836-6.728 6.477v.134a6.595 6.595 0 0 0 6.617 6.581 6.595 6.595 0 0 0 6.581-6.616c-.005-3.583-2.882-6.506-6.47-6.576zM107.601 92.134a6.619 6.619 0 0 0-6.616 6.617 6.619 6.619 0 0 0 6.616 6.616 6.619 6.619 0 0 0 6.617-6.616 6.615 6.615 0 0 0-6.617-6.617zM73.638 82.81a6.617 6.617 0 0 0-6.576-11.453l-.04.024a6.62 6.62 0 0 0-2.988 8.868 6.62 6.62 0 0 0 9.604 2.562zM92.274 82.81a6.619 6.619 0 0 0 8.868-2.987 6.62 6.62 0 0 0-2.252-8.443l-.035-.023a6.613 6.613 0 0 0-8.863 2.993 6.625 6.625 0 0 0 2.282 8.46zM57.915 92.158c-3.652-.012-6.622 2.946-6.634 6.599-.011 3.652 2.947 6.622 6.6 6.634a6.62 6.62 0 0 0 6.633-6.6v-.017a6.595 6.595 0 0 0-6.575-6.616h-.024z"
          ></path>
        </svg>
      </Icon>
    </>
  );
};
